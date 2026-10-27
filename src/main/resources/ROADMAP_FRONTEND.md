using Cmacica.Aplicacion.Seguridad.DTO.Colocaciones.Comun;
using Cmacica.Aplicacion.Seguridad.DTO.Colocaciones.ProcesoCredito;
using Cmacica.Aplicacion.Seguridad.DTO.Colocaciones.ProcesoCredito.Normal;
using Cmacica.Aplicacion.Seguridad.DTO.Colocaciones.Recuperaciones.Cobranza;
using Cmacica.Aplicacion.Seguridad.DTO.General;
using Cmacica.Aplicacion.Seguridad.DTO.General.ValidacionResultado;
using Cmacica.Servicios.Seguridad.Interface;
using Cmacica.Servicios.Seguridad.Interface.Colocaciones.FlujoCredito;
using CmacIca.Datos.Seguridad.Dominio.Clientes.Credito.DesembolsoCredito;
using CmacIca.Datos.Seguridad.Dominio.Clientes.ProgramacionCobranzaNotif;
using CmacIca.Datos.Seguridad.Dominio.Modelos.ProgramacionCobranzaNotif;
using CmacIca.Datos.Seguridad.Peticiones.Configuracion.Inyector;
using CmacIca.MVVMBase.MessagingService;
using CmacIca.MVVMBase.ViewModel;
using CmacIca.Presentacion.AgenteServicio.Agente;
using CmacIca.Presentacion.AgenteServicio.Constantes;
using CmacIca.WPF.Comun.Helpers;
using CmacIca.WPF.Creditos.Interfaces.View.Colocaciones.Recuperaciones.Cobranza;
using CmacIca.WPF.Creditos.Interfaces.ViewModel.Colocaciones.Recuperaciones.Cobranza;
using Microsoft.Practices.Prism.Commands;
using Microsoft.Practices.Prism.Regions;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.ComponentModel.Composition;
using System.Linq;
using System.Windows;
using CmacIca.WPF.Creditos.Model.Recuperaciones.ProgramacionNotifCobranza;
using OfficeOpenXml;
using System.IO;
using System.Threading.Tasks;
using DialogResult = System.Windows.Forms.DialogResult;
using OpenFileDialog = System.Windows.Forms.OpenFileDialog;
using SaveFileDialog = System.Windows.Forms.SaveFileDialog;

namespace CmacIca.WPF.Creditos.ViewModel.Colocaciones.Recuperaciones.Cobranza
{
[Export(typeof(IProgramarNotificacionCobranzaViewModel))]
public class ProgramarNotificacionCobranzaViewModel : BaseViewModel, IProgramarNotificacionCobranzaViewModel
{
#region Inyecciones de dependencia
IProgramacionCobranzaNotifDataClient _programacionCobranzaNotifDataClient = InyectorID.Inject<IProgramacionCobranzaNotifDataClient>();
#endregion

        private readonly IMessagingService _messagingService;
        private IRegionManager _admRegion = new RegionManager();
        private TimeSpan maxHora;
        private TimeSpan minRestriccion;
        public event Action OnActualizarBlackoutDates;
        public event EventHandler LimpiarFechasVista;


        [ImportingConstructor]
        public ProgramarNotificacionCobranzaViewModel(IProgramarNotificacionCobranzaView vista) : base(vista)
        {
            _messagingService = MessageServiceFactory.GetMessagingServiceInstance();
            CmdSalir = new DelegateCommand(OnSalir);
            CmdGuardar = new DelegateCommand(OnGuardar);
            FechasSeleccionadas = new ObservableCollection<DateTime>();
            FechasHorasSeleccionadas = new ObservableCollection<DateTime>();
            CmdCheckListBox = new DelegateCommand(OnCheckListBox);
            CmdDescargarPlantillaExcel = new DelegateCommand(OnDescargarPlantillaExcel);
            CmdImportarExcel = new DelegateCommand(OnImportarExcel);
            CmdContinuarExcel = new DelegateCommand(OnContinuarExcel);
            CmdEliminarCreditoExcel = new DelegateCommand<ProgramacionNotificacionCobranzaExcelModel>(OnEliminarCreditoExcel);
            CmdPaginaAnteriorExcel = new DelegateCommand(OnPaginaAnteriorExcel);
            CmdPaginaSiguienteExcel = new DelegateCommand(OnPaginaSiguienteExcel);
            ListaProductosTodos = new ObservableCollection<MultipleCredProductosModel>();
            OnListarTipoCredito(1);
            ListaModNotificacion = OnCargarConstante(64000121);
            ListaTipoPersoneria = OnCargarConstante(100027);
            ListarFeriados();
            //HoraProgramada = new DateTime(DateTime.Now.Year, DateTime.Now.Month, DateTime.Now.Day, 7, 00, 00);
            // maxHora = new DateTime(DateTime.Now.Year, DateTime.Now.Month, DateTime.Now.Day, 20, 00, 00);
            maxHora = new TimeSpan(20, 00, 00);
            minRestriccion = new TimeSpan(00, 10, 00);
            ListaTipoAtraso = OnCargarConstante(29);
            OpcionesTamanoPaginaExcel = new ObservableCollection<int>() { 10, 20, 50 };
            _listaModNotificacionMasiva = new ObservableCollection<ConstanteDto>(ListaModNotificacion ?? new ObservableCollection<ConstanteDto>());

            OnInicializarView();
        }

        #region Comandos
        public DelegateCommand CmdSalir { get; set; }
        public DelegateCommand<object> CmdSelectParticularDay { get; set; }
        public DelegateCommand<object> CmdClearSelectedDaysinMonth { get; set; }
        public DelegateCommand CmdGuardar { get; set; }
        public DelegateCommand CmdCheckListBox { get; set; }
        public DelegateCommand CmdDescargarPlantillaExcel { get; set; }
        public DelegateCommand CmdImportarExcel { get; set; }
        public DelegateCommand CmdContinuarExcel { get; set; }
        public DelegateCommand<ProgramacionNotificacionCobranzaExcelModel> CmdEliminarCreditoExcel { get; set; }
        public DelegateCommand CmdPaginaAnteriorExcel { get; set; }
        public DelegateCommand CmdPaginaSiguienteExcel { get; set; }

        //public DelegateCommand CmdSelectParticularDay { get; set; }
        #endregion

        #region Metodos


        public new void OnInicializarView()
        {
            OnLimpiar();
            isVisibledRangoAtrasos = Visibility.Collapsed;
            isVisibleListaSpeech = Visibility.Collapsed;
            ListaSpeech = OnCargarConstante(27);
            isVisibledSeleccionarTodo = Visibility.Collapsed;
        }


        private void OnGuardar()
        {
            if (EsProgramacionExcel)
            {
                OnGuardarProgramacionExcel();
                return;
            }

            try
            {
                using (var agente = new ServiceAgent<ISrvColocaciones>())
                {
                    if ((HoraProgramada - DateTime.Now.TimeOfDay) < minRestriccion && FechasSeleccionadas.Contains(DateTime.Now.Date))
                    {
                        _messagingService.ShowMessage(String.Format("La programacion debe hacerse con minimo 10 minutos de antelacion cuando se incluye el dia actual"), "Mensaje informativo", DialogType.Message);
                        return;
                    }
                    if (TipoModNotificacion == null)
                    {
                        _messagingService.ShowMessage(String.Format("Debe seleccionar una modalidad correcta."), "Mensaje informativo", DialogType.Message);
                        return;
                    }
                    if (TipoPersoneria == null)
                    {
                        _messagingService.ShowMessage(String.Format("Debe seleccionar un tipo de personeria correcto."), "Mensaje informativo", DialogType.Message);
                        return;
                    }
                    if (FechasSeleccionadas.Count() == 0)
                    {
                        _messagingService.ShowMessage(String.Format("Debe seleccionar una o mas fechas correctas."), "Mensaje informativo", DialogType.Message);
                        return;
                    }
                    if (HoraProgramada > maxHora)
                    {
                        _messagingService.ShowMessage(String.Format("Debe ingresar una hora menor a 20:00 hrs"), "Mensaje informativo", DialogType.Message);
                        return;
                    }
                    if (MontoCapitalMaximo == 0)
                    {
                        _messagingService.ShowMessage(String.Format("Debe ingresar un monto de saldo mayor a cero."), "Mensaje informativo", DialogType.Message);
                        return;
                    }
                    if (TipoAtraso == null)
                    {
                        _messagingService.ShowMessage(String.Format("Debe Seleccionar un tipo de atraso"), "Mensaje informativo", DialogType.Message);
                        return;
                    }
                    if (!ListaTipoCreditos.Any(x => x.bSeleccionado == true))
                    {
                        _messagingService.ShowMessage(String.Format("Debe seleccionar uno o mas tipos de crédito."), "Mensaje informativo", DialogType.Message);
                        return;
                    }
                    if (!ListaProductos.Any(x => x.bSeleccionado == true))
                    {
                        _messagingService.ShowMessage(String.Format("Debe seleccionar uno o mas productos."), "Mensaje informativo", DialogType.Message);
                        return;
                    }
                    if (SpeechSeleccionado == null && TipoModNotificacion.CodigoValor == 1)
                    {
                        _messagingService.ShowMessage(String.Format("Debe seleccionar un speech correcto."), "Mensaje informativo", DialogType.Message);
                        return;
                    }


                    var mensaje = _messagingService.ShowMessage("¿Está seguro de programar la notificación?", "Aviso", DialogType.Question);
                    if (mensaje != DialogResponse.Yes)
                    {
                        return;
                    }

                    var entiModel = new ProgramacionNotificacionCobranzaModel();
                    entiModel.TipoModNotiCodVal = TipoModNotificacion.CodigoValor;
                    entiModel.cUsuario = VariablesGlobales.DatosSesion.cNombreUsuario;
                    entiModel.DiasAtrasoMinimo = DiasAtrasoMinimo;
                    entiModel.DiasAtrasoMaximo = DiasAtrasoMaximo;
                    entiModel.MontoCapitalMinimo = MontoCapitalMinimo;
                    entiModel.MontoCapitalMaximo = MontoCapitalMaximo;
                    foreach (var fecha in FechasSeleccionadas)
                    {
                        if (!ListaFechasBloqueadas.Contains(fecha.Date))
                        {
                            DateTime formatFecha = fecha.Date + HoraProgramada;

                            FechasHorasSeleccionadas.Add(formatFecha);
                        }
                    }

                    if(FechasHorasSeleccionadas == null || !FechasHorasSeleccionadas.Any())
                    {
                        _messagingService.ShowMessage(String.Format("La Fechas seleccionadas no son validas"), "Mensaje informativo", DialogType.Message);
                        return;
                    }

                    entiModel.FechasSeleccionadas = FechasHorasSeleccionadas;

                    entiModel.nTipoPersoneria = TipoPersoneria.CodigoValor;
                    entiModel.cSpeech = SpeechSeleccionado != null ? SpeechSeleccionado.Descripcion : "";
                    entiModel.ListaProductos = ListaProductos.Where(x => x.bSeleccionado)
                    .Select(x => new ProductoProgramacionCobranzaModel
                    {
                        cCredProductos = x.cCredProductos,
                        cDescripcion = x.cDescripcion,
                        nTipoCred = x.nTipoCreditos
                    })
                    .ToList();

                    entiModel.ListaProgramGob = ListaProgramaGob.Where(x => x.bSeleccionado).ToList();

                    _programacionCobranzaNotifDataClient.RegistrarProgramacionNotificacionCobranza(entiModel);
                    _messagingService.ShowMessage(String.Format("La programación se ha realizado de manera correcta."), "Mensaje informativo", DialogType.Message);
                    OnLimpiar();
                }
            }catch(Exception ex)
            {
                ManejoErrores(ex);
            }
        }

        private void OnLimpiar()
        {
            OnLimpiarFechasProgramacion();
            _tipoModNotificacion = null;
            OnPropertyChanged(() => TipoModNotificacion);
            TipoPersoneria = null;
            DiasAtrasoMinimo = new int();
            DiasAtrasoMaximo = new int();
            MontoCapitalMinimo = new decimal();
            MontoCapitalMaximo = new decimal();
            var vListaTipoCreditos = ListaTipoCreditos.ToList();
            vListaTipoCreditos.ForEach(x => x.bSeleccionado = false);
            ListaTipoCreditos = new ObservableCollection<MultipleTipoCreditosModel>(vListaTipoCreditos);
            ListaProductos = new ObservableCollection<MultipleCredProductosModel>();
            ListaProductosTodos = new ObservableCollection<MultipleCredProductosModel>();
            SpeechSeleccionado = null;
            TipoAtraso = null;
            IsEnabledTipoPersoneria = false;
            IsEnabledFiltros = false;
            IsEnabledHorario = false;
            IsEnabledSpeech = false;
            IsEnabledTipoCredito = false;
            IsEnabledProducto = false;
            IsEnabledSaldo = false;
            isVisibledRangoAtrasos = Visibility.Collapsed;
            isVisibleListaSpeech = Visibility.Collapsed;
            ListaSpeechFiltrado = new ObservableCollection<ConstanteDto>();
            OnListarProgramaGob();

            _versionProgramacionExcel++;
            OnSuscribirCambiosCreditosExcel(false);
            _listaProgramacionesExcel = new ObservableCollection<ProgramacionNotificacionCobranzaExcelModel>();
            _listaCreditosValidadosExcel = new ObservableCollection<ProgramacionNotificacionCobranzaExcelModel>();
            _tipoModNotificacionExcel = null;
            _validacionMedioExcelCompleta = false;
            _mostrarObservadosExcel = false;
            _esSpeechAutomaticoExcel = true;
            _esSpeechManualExcel = false;
            RutaArchivoExcel = string.Empty;
            PaginaActualExcel = 1;
            BusyContent = "Espere un momento por favor...";

            EsMedioSmsExcel = false;
            IsEnabledImportarExcel = false;
            IsEnabledContinuarExcel = false;
            IsEnabledGuardar = EsProgramacionMasiva;
            IsEnabledCalendario = true;
            VisibilidadProgramacionMasiva = EsProgramacionMasiva ? Visibility.Visible : Visibility.Collapsed;
            VisibilidadProgramacionExcel = EsProgramacionExcel ? Visibility.Visible : Visibility.Collapsed;
            VisibilidadSpeechMasivo = Visibility.Collapsed;
            VisibilidadObservadosExcel = Visibility.Collapsed;
            VisibilidadValidadosExcel = Visibility.Collapsed;
            VisibilidadGuardar = EsProgramacionMasiva ? Visibility.Visible : Visibility.Collapsed;
            VisibilidadModoSpeechExcel = Visibility.Collapsed;
            VisibilidadSpeechPendientesExcel = Visibility.Collapsed;
            OnPropertyChanged(() => EsSpeechAutomaticoExcel);
            OnPropertyChanged(() => EsSpeechManualExcel);
            OnActualizarResumenExcel();
            OnActualizarPaginacionExcel();
            ActualizarCalendarioExcel?.Invoke(this, EventArgs.Empty);
        }

        private void OnLimpiarFechasProgramacion()
        {
            FechasSeleccionadas = new ObservableCollection<DateTime>();
            FechasHorasSeleccionadas = new ObservableCollection<DateTime>();
            LimpiarFechasVista?.Invoke(this, EventArgs.Empty);
            HoraProgramada = DateTime.Now.AddMinutes(30).TimeOfDay;
            HoraProgramada = new TimeSpan(HoraProgramada.Hours, HoraProgramada.Minutes, 0);
        }

        private void ListarFeriados()
        {
            using (var agente = new ServiceAgent<ISrvGeneral>())
            {
                ListaFeriados = agente.CrearServicio(EndpointService.EdpBasico).ObtenerListaFeriados(DateTime.Now, DateTime.MaxValue);
            }
            OnActualizarBlackoutDates.Invoke(); //Invoca el evento para bloquear las fechas
        }

        private void OnCheckListBox()
        {
            OnListarProductos();
        }

        private void OnListarTipoCredito(int pTipoDocumrnto)
        {
            try
            {
                List<MultipleTipoCreditosModel> resultadoConvertido;
                List<TipoCreditosDto> resultado = new List<TipoCreditosDto>();
                using (var agente = new ServiceAgent<ISrvFluCreSolicitud>())
                {
                    var entiBase = new SolCredBaseDto
                    {
                        nTipoPersona = pTipoDocumrnto
                    };
                    resultado = agente.CrearServicio(EndpointService.EdpBasico).ListaTipoCreditos(entiBase);
                    resultadoConvertido = JsonConvert.DeserializeObject<List<MultipleTipoCreditosModel>>(JsonConvert.SerializeObject(resultado));
                }
                _listaTipoCreditos = new ObservableCollection<MultipleTipoCreditosModel>(resultadoConvertido);
                OnPropertyChanged(() => ListaTipoCreditos);
            }
            catch (Exception ex)
            {
                ManejoErrores(ex);
            }
        }

        private void OnSalir()
        {
            if (!EsProgramacionExcel)
            {
                CancelSelected();
                OnLimpiar();
                return;
            }

            if (!PuedeCambiarSeleccionActual ||
                (OnTieneCargaProgramacionExcel() &&
                 !OnConfirmarAccionExcel("Se perderá la lista cargada. ¿Desea salir?")))
            {
                return;
            }

            _reiniciandoProgramacionExcel = true;
            try
            {
                CancelSelected();
                OnLimpiar();
                _esProgramacionExcel = false;
                ListaModNotificacion = new ObservableCollection<ConstanteDto>(_listaModNotificacionMasiva);
                VisibilidadProgramacionMasiva = Visibility.Visible;
                VisibilidadProgramacionExcel = Visibility.Collapsed;
                VisibilidadGuardar = Visibility.Visible;
                IsEnabledGuardar = true;
            }
            finally
            {
                _reiniciandoProgramacionExcel = false;
                OnPropertyChanged(() => EsProgramacionExcel);
                OnPropertyChanged(() => EsProgramacionMasiva);
            }
        }

        private void OnListarProductos()
        {
            OnLimpiarProducto();
            try
            {
                if (!ListaTipoCreditos.Any(x => x.bSeleccionado))
                {
                    isVisibledSeleccionarTodo = Visibility.Collapsed;
                    return;
                }

                foreach (var item in ListaTipoCreditos.Where(x => x.bSeleccionado))
                {
                    using (var agente = new ServiceAgent<ISrvFluCreSolicitud>())
                    {
                        List<MultipleCredProductosModel> resultado = new List<MultipleCredProductosModel>();
                        var entibase = new SolCredBaseDto();
                        //entibase.nCodCredProceso = ProcesoSeleccionado.nCodCredProceso;
                        entibase.nTipoCredito = item.nTipoCreditos;
                        entibase.bLineaCred = false;
                        entibase.CodAgencia = VariablesGlobales.DatosSesion.AgenciaSesion.CodigoAgencia;
                        //productos del flujo agricola que son excluidos
                        string cosntatespermitidas = base.OnCargarConstSistema(2126).nConsSisValor;
                        string[] codigosA = cosntatespermitidas.Split(',');
                        if (ListaProductosTodos.Any(x => x.nTipoCreditos == item.nTipoCreditos))
                        {
                            var listaExistente = ListaProductosTodos.Where(x => x.nTipoCreditos == item.nTipoCreditos).ToList();
                            resultado = listaExistente;
                        }
                        else
                        {
                            var listaNueva = agente.CrearServicio(EndpointService.EdpBasico).ListaCredProductos(entibase);
                            var resultadoConvertido = JsonConvert.DeserializeObject<List<MultipleCredProductosModel>>(JsonConvert.SerializeObject(listaNueva));
                            resultadoConvertido.ForEach(z => z.nTipoCreditos = item.nTipoCreditos);
                            resultado = resultadoConvertido;
                            ListaProductosTodos = new ObservableCollection<MultipleCredProductosModel>(ListaProductosTodos.Union(resultadoConvertido).ToList());
                            //ListaProductosTodos.ToList().ForEach(z => z.bSeleccionado = false);
                        }
                        var transformado = new ObservableCollection<MultipleCredProductosModel>(resultado.Where(x => !codigosA.Contains(x.cCredProductos.Substring(0, 3))));
                        ListaProductos = new ObservableCollection<MultipleCredProductosModel>(ListaProductos.Union(transformado).ToList());
                    }
                }
                if(ListaProductos.Count()>0)
                    isVisibledSeleccionarTodo = Visibility.Visible;


            }
            catch (Exception ex)
            {
                ManejoErrores(ex);
            }
        }

        private void OnLimpiarProducto()
        {
            ListaProductos = new ObservableCollection<MultipleCredProductosModel>();
        }

        private void Producto_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == "bSeleccionado")
            {
                VerificarSeleccionarTodos();
            }
        }

        private void tipoCredito_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == "bSeleccionado")
            {
                DeseleccionarProductos();
            }
        }

        public void programGob_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == "bSeleccionado")
            {
                var item = sender as ProgramaGobNotifModel;
                if (item != null)
                {
                    FiltrarListaSpeech();
                }
            }
        }


        private void VerificarSeleccionarTodos()
        {
            if (ListaProductos == null || ListaProductos.Count == 0)
            {
                SeleccionarTodos = false;
                return;
            }

            // Verifica si todos están seleccionados
            bool todosSeleccionados = ListaProductos.All(p => p.bSeleccionado);

            // Esto evita la recursión innecesaria
            if (_seleccionarTodos != todosSeleccionados)
            {
                _seleccionarTodos = todosSeleccionados;
                OnPropertyChanged(() => SeleccionarTodos);
            }
        }

        private void DeseleccionarProductos()
        {
            foreach (var tipoCredito in _listaTipoCreditos)
            {
                if (!tipoCredito.bSeleccionado)
                {
                    foreach (var producto in ListaProductosTodos.Where(z => z.nTipoCreditos == tipoCredito.nTipoCreditos))
                    {
                        producto.bSeleccionado = false;
                    }
                }

            }

        }

        private void OnListarProgramaGob()
        {
            try
            {
                ListaProgramaGob = new ObservableCollection<ProgramaGobNotifModel>(_programacionCobranzaNotifDataClient.ListarProgramaGob());
            }
            catch (Exception ex) {

                ManejoErrores(ex);

            }
        }

        private void FiltrarListaSpeech()
        {
            if (TipoAtraso ==null || TipoPersoneria == null || TipoModNotificacion.CodigoValor == 2) return;
            var eqv = "";
            if (TipoAtraso.CodigoValor == 1)//0 dias de atraso
            {
                if (TipoPersoneria.CodigoValor == 1) //Personas Naturales
                {
                    eqv = "1";
                }
                else if (TipoPersoneria.CodigoValor == 2) //Personas Juridicas
                {
                    eqv = "3";
                }
            }
            else if (TipoAtraso.CodigoValor == 2)//>=1 dias de atraso
            {
                if (TipoPersoneria.CodigoValor == 1) //Personas Naturales
                {
                    eqv = "2";
                }
                else if (TipoPersoneria.CodigoValor == 2) //Personas Juridicas
                {
                    eqv = "4";
                }
            }else if (TipoAtraso.CodigoValor == 3)//<0 dias de atras
            {
                if (TipoPersoneria.CodigoValor == 1) //Personas Naturales
                {
                    eqv = "5";
                }
                else if (TipoPersoneria.CodigoValor == 2) //Personas Juridicas
                {
                    eqv = "6";
                }
            }

            if (TipoAtraso.CodigoValor > 0 && ListaProgramaGob.Any(x=>x.bSeleccionado))
            {
                if (TipoPersoneria.CodigoValor == 1) //Personas Naturales
                {
                    eqv = "7";
                }
                else if (TipoPersoneria.CodigoValor == 2) //Personas Juridicas
                {
                    eqv = "8";
                }
            }

            ListaSpeechFiltrado = new ObservableCollection<ConstanteDto>(
                ListaSpeech.Where(x => x.Equivalente == eqv)
            );
        }

        public void Habilitarform()
        {
            IsEnabledFiltros = true;
            IsEnabledHorario = true;
            IsEnabledSpeech = true;
            IsEnabledTipoCredito = true;
            IsEnabledProducto = true;
            IsEnabledSaldo = true;
        }


        #endregion

        #region Propiedades

        #region ProgramacionComunicacionCobranza
        private ProgramacionNotificacionCobranzaDto _programacionComunicacionCobranza;
        public ProgramacionNotificacionCobranzaDto ProgramacionComunicacionCobranza
        {
            get { return _programacionComunicacionCobranza; }
            set
            {
                _programacionComunicacionCobranza = value;
                OnPropertyChanged(() => ProgramacionComunicacionCobranza);
            }
        }
        #endregion

        #region TipoModNotificacion
        private ConstanteDto _tipoModNotificacion;
        public ConstanteDto TipoModNotificacion
        {
            get { return _tipoModNotificacion; }
            set
            {
                if (EsProgramacionExcel)
                {
                    OnSeleccionarModalidadExcel(value);
                    return;
                }

                _tipoModNotificacion = value;
                if (_tipoModNotificacion != null)
                {
                    IsEnabledTipoPersoneria = true;

                    if (_tipoModNotificacion.CodigoValor == 1)
                    {
                        isVisibleListaSpeech = Visibility.Visible;
                    }
                    else if (_tipoModNotificacion.CodigoValor == 2)
                    {
                        isVisibleListaSpeech = Visibility.Collapsed;
                        SpeechSeleccionado = null;
                    }
                }
                OnPropertyChanged(() => TipoModNotificacion);
            }
        }
        #endregion
        #region TipoPersoneria
        private ConstanteDto _tipoPersoneria;
        public ConstanteDto TipoPersoneria
        {
            get { return _tipoPersoneria; }
            set
            {
                _tipoPersoneria = value;
                if (_tipoPersoneria != null)
                    Habilitarform();

                OnPropertyChanged(() => TipoPersoneria);
                FiltrarListaSpeech();
            }
        }
        #endregion

        #region TipoAtraso
        private ConstanteDto _tipoAtraso;// 0: 0 dias, 1: >1 dias
        public ConstanteDto TipoAtraso
        {
            get { return _tipoAtraso; }
            set
            {
                _tipoAtraso = value;
                if (_tipoAtraso != null)
                {
                    if (_tipoAtraso.CodigoValor == 1)
                    {
                        isVisibledRangoAtrasos = Visibility.Collapsed;
                        DiasAtrasoMinimo = 0;
                        DiasAtrasoMaximo = 0;
                    }
                    else if (_tipoAtraso.CodigoValor == 2)
                    {
                        isVisibledRangoAtrasos = Visibility.Visible;
                        DiasAtrasoMinimo = 1;
                        DiasAtrasoMaximo = 1;
                        minUntil = 1;
                        minFrom = 1;
                        maxUntil = int.MaxValue;

                    }else if (_tipoAtraso.CodigoValor == 3)
                    {
                        isVisibledRangoAtrasos = Visibility.Visible;
                        maxUntil = -1;
                        DiasAtrasoMaximo = -1;
                        DiasAtrasoMinimo = -1;
                        maxFrom = -1;
                        minUntil = -1;
                        minFrom = int.MinValue;


                    }

                }
                OnPropertyChanged(() => TipoAtraso);
                FiltrarListaSpeech();
            }
        }
        #endregion

        #region ListaModNotificacion
        private ObservableCollection<ConstanteDto> _listaModNotificacion;
        public ObservableCollection<ConstanteDto> ListaModNotificacion
        {
            get { return _listaModNotificacion; }
            set
            {
                _listaModNotificacion = value;
                OnPropertyChanged(() => ListaModNotificacion);
            }
        }
        #endregion

        #region ListaTipoPersoneria
        private ObservableCollection<ConstanteDto> _listaTipoPersoneria;
        public ObservableCollection<ConstanteDto> ListaTipoPersoneria
        {
            get { return _listaTipoPersoneria; }
            set
            {
                _listaTipoPersoneria = value;
                OnPropertyChanged(() => ListaTipoPersoneria);
            }
        }
        #endregion

        #region ListaTipoAtraso
        private ObservableCollection<ConstanteDto> _listaTipoAtraso;
        public ObservableCollection<ConstanteDto> ListaTipoAtraso
        {
            get { return _listaTipoAtraso; }
            set
            {
                _listaTipoAtraso = value;
                OnPropertyChanged(() => ListaTipoAtraso);
            }
        }
        #endregion

        #region ListaSpeech
        private ObservableCollection<ConstanteDto> _listaSpeech;
        public ObservableCollection<ConstanteDto> ListaSpeech
        {
            get { return _listaSpeech; }
            set
            {
                _listaSpeech = value;
                OnPropertyChanged(() => ListaSpeech);
            }
        }
        #endregion

        #region ListaSpeechFiltrado
        private ObservableCollection<ConstanteDto> _listaSpeechFiltrado;
        public ObservableCollection<ConstanteDto> ListaSpeechFiltrado
        {
            get { return _listaSpeechFiltrado; }
            set
            {
                _listaSpeechFiltrado = value;
                OnPropertyChanged(() => ListaSpeechFiltrado);
            }
        }
        #endregion

        #region ScriptSeleccionado
        private ConstanteDto _speechSeleccionado;
        public ConstanteDto SpeechSeleccionado
        {
            get { return _speechSeleccionado; }
            set
            {
                _speechSeleccionado = value;
                OnPropertyChanged(() => SpeechSeleccionado);
            }
        }
        #endregion

        #region HoraProgramada
        private TimeSpan _horaProgramada;
        public TimeSpan HoraProgramada
        {
            get { return _horaProgramada; }
            set
            {
                _horaProgramada = value;
                OnPropertyChanged(() => HoraProgramada);
            }
        }
        #endregion

        #region ListaProductos
        private ObservableCollection<MultipleCredProductosModel> _listaProductos;
        public ObservableCollection<MultipleCredProductosModel> ListaProductos
        {
            get { return _listaProductos; }
            set
            {
                if (_listaProductos != null)
                {
                    foreach (var oldItem in _listaProductos)
                        oldItem.PropertyChanged -= Producto_PropertyChanged;
                }

                _listaProductos = value;

                if (_listaProductos != null)
                {
                    foreach (var producto in _listaProductos)
                        producto.PropertyChanged += Producto_PropertyChanged;
                }

                OnPropertyChanged(() => ListaProductos);
                OnPropertyChanged(() => ListaTipoCreditos);

                VerificarSeleccionarTodos(); // también actualiza SeleccionarTodos si corresponde
            }
        }
        #endregion

        #region ProductoSeleccionado
        private MultipleCredProductosModel _productoSeleccionado;
        public MultipleCredProductosModel ProductoSeleccionado
        {
            get { return _productoSeleccionado; }
            set
            {
                _productoSeleccionado = value;
                OnPropertyChanged(() => ProductoSeleccionado);
            }
        }
        #endregion

        #region isVisibledSeleccionarTodo
        private Visibility _isVisibledSeleccionarTodo;
        public Visibility isVisibledSeleccionarTodo
        {
            get { return _isVisibledSeleccionarTodo; }
            set
            {
                if (_isVisibledSeleccionarTodo != value)
                {
                    _isVisibledSeleccionarTodo = value;
                    OnPropertyChanged(()=>isVisibledSeleccionarTodo);
                }
            }
        }
        #endregion

        #region isVisibledRangoAtrasos
        private Visibility _isVisibledRangoAtrasos;
        public Visibility isVisibledRangoAtrasos
        {
            get { return _isVisibledRangoAtrasos; }
            set
            {
                if (_isVisibledRangoAtrasos != value)
                {
                    _isVisibledRangoAtrasos = value;
                    OnPropertyChanged(() => isVisibledRangoAtrasos);
                }
            }
        }
        #endregion

        #region isVisibledRangoAtrasos
        private Visibility _isVisibleListaSpeech;
        public Visibility isVisibleListaSpeech
        {
            get { return _isVisibleListaSpeech; }
            set
            {
                if (_isVisibleListaSpeech != value)
                {
                    _isVisibleListaSpeech = value;
                    OnPropertyChanged(() => isVisibleListaSpeech);
                    VisibilidadSpeechMasivo = EsProgramacionMasiva ? _isVisibleListaSpeech : Visibility.Collapsed;
                }
            }
        }
        #endregion

        #region SeleccionarTodo
        private bool _seleccionarTodos;
        public bool SeleccionarTodos
        {
            get { return _seleccionarTodos; }
            set
            {
                if (_seleccionarTodos != value)
                {
                    _seleccionarTodos = value;

                    OnPropertyChanged(() => SeleccionarTodos);

                    if (ListaProductos != null)
                    {
                        foreach (var producto in ListaProductos)
                        {
                            producto.bSeleccionado = value;
                        }
                    }
                }
            }
        }
        #endregion

        #region ListaProductosTodos
        private ObservableCollection<MultipleCredProductosModel> _listaProductosTodos;
        public ObservableCollection<MultipleCredProductosModel> ListaProductosTodos
        {
            get { return _listaProductosTodos; }
            set
            {
                _listaProductosTodos = value;
                OnPropertyChanged(() => ListaProductosTodos);
            }
        }
        #endregion

        #region FechasSeleccionadas
        private ObservableCollection<DateTime> _fechasSeleccionadas;
        public ObservableCollection<DateTime> FechasSeleccionadas
        {
            get {
                return _fechasSeleccionadas;
            }
            set
            {
                _fechasSeleccionadas = value;
                OnPropertyChanged(() => FechasSeleccionadas);
            }
        }

        #endregion

        #region FechasSeleccionadas
        private ObservableCollection<DateTime> _fechasHorasSeleccionadas;
        public ObservableCollection<DateTime> FechasHorasSeleccionadas
        {
            get
            {
                return _fechasHorasSeleccionadas;
            }
            set
            {
                _fechasHorasSeleccionadas = value;
                OnPropertyChanged(() => FechasHorasSeleccionadas);
            }
        }

        #endregion

        #region ListaFeriados
        private List<DateTime> _listaFeriados;
        public List<DateTime> ListaFeriados
        {
            get
            {
                return _listaFeriados;
            }
            set
            {
                _listaFeriados = value;
                OnPropertyChanged(() => ListaFeriados);
            }
        }

        #endregion

        #region ListaFeriados
        private List<DateTime> _listaFechasBloqueadas;
        public List<DateTime> ListaFechasBloqueadas
        {
            get
            {
                return _listaFechasBloqueadas;
            }
            set
            {
                _listaFechasBloqueadas = value;
                OnPropertyChanged(() => ListaFechasBloqueadas);
            }
        }

        #endregion

        #region Tipo de crédito

        #region ListaTipoCreditos
        private ObservableCollection<MultipleTipoCreditosModel> _listaTipoCreditos;
        public ObservableCollection<MultipleTipoCreditosModel> ListaTipoCreditos
        {
            get { return _listaTipoCreditos; }
            set
            {
                if (_listaTipoCreditos != null)
                {
                    foreach (var oldItem in _listaTipoCreditos)
                        oldItem.PropertyChanged -= tipoCredito_PropertyChanged;
                }

                _listaTipoCreditos = value;

                if (_listaTipoCreditos != null)
                {
                    foreach (var producto in _listaTipoCreditos)
                        producto.PropertyChanged += tipoCredito_PropertyChanged;
                }



                OnPropertyChanged(() => ListaTipoCreditos);
            }
        }
        #endregion

        #region TipoCreditoSeleccionado

        private TipoCreditosDto _tipoCreditoSeleccionado;

        public TipoCreditosDto TipoCreditoSeleccionado
        {
            get { return _tipoCreditoSeleccionado; }
            set
            {
                _tipoCreditoSeleccionado = value;
                OnPropertyChanged(() => TipoCreditoSeleccionado);
            }
        }

        #endregion

        #endregion

        #region DiasAtrasoMinimo

        private int _diasAtrasoMinimo;

        public int DiasAtrasoMinimo
        {
            get { return _diasAtrasoMinimo; }
            set
            {
                if(TipoAtraso !=null && TipoAtraso.CodigoValor == 3)
                {
                    if (value < 0)
                    {
                        _diasAtrasoMinimo = value;
                    }

                }
                else
                {
                    _diasAtrasoMinimo = value;
                }

                minUntil = _diasAtrasoMinimo;


                OnPropertyChanged(() => DiasAtrasoMinimo);
            }
        }

        #endregion

        #region DiasAtrasoMaximo

        private int _diasAtrasoMaximo;

        public int DiasAtrasoMaximo
        {
            get { return _diasAtrasoMaximo; }
            set
            {
                if (TipoAtraso != null && TipoAtraso.CodigoValor == 3)
                {
                    if (value < 0)
                    {
                        _diasAtrasoMaximo = value;
                    }

                }
                else
                {
                    _diasAtrasoMaximo = value;
                }

                maxFrom = _diasAtrasoMaximo;


                OnPropertyChanged(() => DiasAtrasoMaximo);
            }
        }

        #endregion

        #region MontoCapitalMinimo

        private decimal _montoCapitalMinimo;
        public decimal MontoCapitalMinimo
        {
            get { return _montoCapitalMinimo; }
            set
            {
                _montoCapitalMinimo = value;
                OnPropertyChanged(() => MontoCapitalMinimo);
            }
        }

        #endregion

        #region MontoCapitalMaximo

        private decimal _montoCapitalMaximo;
        public decimal MontoCapitalMaximo
        {
            get { return _montoCapitalMaximo; }
            set
            {
                _montoCapitalMaximo = value;
                OnPropertyChanged(() => MontoCapitalMaximo);
            }
        }

        #endregion


        #region IsEnabledTipoPersoneria
        private bool _isEnabledTipoPersoneria;
        public bool IsEnabledTipoPersoneria
        {
            get { return _isEnabledTipoPersoneria; }
            set
            {
                if (_isEnabledTipoPersoneria != value)
                {
                    _isEnabledTipoPersoneria = value;
                    OnPropertyChanged(() => IsEnabledTipoPersoneria);
                }
            }
        }
        #endregion

        #region IsEnabledFiltros
        private bool _isEnabledFiltros;
        public bool IsEnabledFiltros
        {
            get { return _isEnabledFiltros; }
            set
            {
                if (_isEnabledFiltros != value)
                {
                    _isEnabledFiltros = value;
                    OnPropertyChanged(() => IsEnabledFiltros);
                }
            }
        }
        #endregion

        #region IsEnabledHorario
        private bool _isEnabledHorario;
        public bool IsEnabledHorario
        {
            get { return _isEnabledHorario; }
            set
            {
                if (_isEnabledHorario != value)
                {
                    _isEnabledHorario = value;
                    OnPropertyChanged(() => IsEnabledHorario);
                }
            }
        }
        #endregion

        #region IsEnabledSpeech
        private bool _isEnabledSpeech;
        public bool IsEnabledSpeech
        {
            get { return _isEnabledSpeech; }
            set
            {
                if (_isEnabledSpeech != value)
                {
                    _isEnabledSpeech = value;
                    OnPropertyChanged(() => IsEnabledSpeech);
                }
            }
        }
        #endregion

        #region IsEnabledTipoCredito
        private bool _isEnabledTipoCredito;
        public bool IsEnabledTipoCredito
        {
            get { return _isEnabledTipoCredito; }
            set
            {
                if (_isEnabledTipoCredito != value)
                {
                    _isEnabledTipoCredito = value;
                    OnPropertyChanged(() => IsEnabledTipoCredito);
                }
            }
        }
        #endregion

        #region IsEnabledProducto
        private bool _isEnabledProducto;
        public bool IsEnabledProducto
        {
            get { return _isEnabledProducto; }
            set
            {
                if (_isEnabledProducto != value)
                {
                    _isEnabledProducto = value;
                    OnPropertyChanged(() => IsEnabledProducto);
                }
            }
        }
        #endregion

        #region IsEnabledSaldo
        private bool _isEnabledSaldo;
        public bool IsEnabledSaldo
        {
            get { return _isEnabledSaldo; }
            set
            {
                if (_isEnabledSaldo != value)
                {
                    _isEnabledSaldo = value;
                    OnPropertyChanged(() => IsEnabledSaldo);
                }
            }
        }
        #endregion

        #region ListaProgramaGob
        private ObservableCollection<ProgramaGobNotifModel> _listaProgramaGob;
        public ObservableCollection<ProgramaGobNotifModel> ListaProgramaGob
        {
            get { return _listaProgramaGob; }
            set
            {

                if (_listaProgramaGob != null)
                {

                    foreach (var oldItem in _listaProgramaGob)
                        oldItem.PropertyChanged -= programGob_PropertyChanged;
                }

                _listaProgramaGob = value;

                if (_listaProgramaGob != null)
                {

                    foreach (var oldItem in _listaProgramaGob)
                        oldItem.PropertyChanged += programGob_PropertyChanged;
                }


                OnPropertyChanged(() => ListaProgramaGob);
            }
        }
        #endregion

        #region Minimos y maximos para rango de atrasos

        public int _minFrom;
        public int minFrom
        {
            get { return _minFrom; }
            set
            {
                if (_minFrom != value)
                {
                    _minFrom = value;
                    OnPropertyChanged(() => minFrom);

                }


            }
        }

        public int _maxFrom;
        public int maxFrom
        {
            get { return _maxFrom; }
            set
            {
                if (_maxFrom != value)
                {
                    _maxFrom = value;
                    OnPropertyChanged(() => maxFrom);
                }


            }
        }

        public int _minUntil;
        public int minUntil
        {
            get { return _minUntil; }
            set
            {
                if (_minUntil != value)
                {
                    _minUntil = value;
                    OnPropertyChanged(() => minUntil);
                }


            }
        }

        public int _maxUntil;
        public int maxUntil
        {
            get { return _maxUntil; }
            set
            {
                if(_maxUntil != value)
                {
                    _maxUntil = value;
                    OnPropertyChanged(() => maxUntil);

                }


            }
        }

        #endregion


        #region Programacion Especifica - Excel

        private const string NombreHojaProgramacionExcel = "CreditosNotificacionEspecifica";
        private const string NombreColumnaCreditoExcel = "cCtaCod";
        private const int LongitudCodigoCreditoExcel = 18;
        private const int MedioEnvioSms = 1;
        private const int MedioEnvioCorreo = 2;


        private ObservableCollection<ConstanteDto> _listaModNotificacionMasiva;
        private ConstanteDto _tipoModNotificacionExcel;
        private ObservableCollection<ProgramacionNotificacionCobranzaExcelModel> _listaProgramacionesExcel;
        private ObservableCollection<ProgramacionNotificacionCobranzaExcelModel> _listaCreditosValidadosExcel;
        private bool _mostrarObservadosExcel;
        private bool _validacionMedioExcelCompleta;
        private bool _reiniciandoProgramacionExcel;
        private bool _confirmandoAccionExcel;
        private int _versionProgramacionExcel;
        public event EventHandler ActualizarCalendarioExcel;

        private bool OnConfirmarAccionExcel(string mensaje)
        {
            if (IsBusy || _confirmandoAccionExcel)
            {
                return false;
            }

            _confirmandoAccionExcel = true;
            try
            {
                return _messagingService.ShowMessage(mensaje, "Confirmación", DialogType.Question) == DialogResponse.Yes;
            }
            finally
            {
                _confirmandoAccionExcel = false;
            }
        }

        private void OnSuscribirCambiosCreditosExcel(bool suscribir)
        {
            if (_listaCreditosValidadosExcel == null)
            {
                return;
            }

            foreach (var fila in _listaCreditosValidadosExcel)
            {
                fila.PropertyChanged -= CreditoExcel_PropertyChanged;
                if (suscribir)
                {
                    fila.PropertyChanged += CreditoExcel_PropertyChanged;
                }
            }
        }

        private void OnActualizarResumenExcel()
        {
            CantidadValidosImportadosExcel = _listaCreditosValidadosExcel != null ? _listaCreditosValidadosExcel.Count : 0;
            CantidadObservadosImportadosExcel = _listaProgramacionesExcel != null ? _listaProgramacionesExcel.Count : 0;
            CantidadRegistrosUnicosImportadosExcel = CantidadValidosImportadosExcel + CantidadObservadosImportadosExcel;
            CantidadSpeechPendientesExcel = EsMedioSmsExcel && EsSpeechManualExcel && _listaCreditosValidadosExcel != null
                ? _listaCreditosValidadosExcel.Count(x =>
                    x.SpeechSeleccionado == null ||
                    string.IsNullOrWhiteSpace(x.SpeechSeleccionado.Descripcion) ||
                    x.ListaSpeechDisponibles == null ||
                    !x.ListaSpeechDisponibles.Any(s =>
                        s.CodigoValor == x.SpeechSeleccionado.CodigoValor &&
                        s.Descripcion == x.SpeechSeleccionado.Descripcion))
                : 0;
        }

        private void OnHabilitarBotonesExcel()
        {
            bool modalidadValida = TipoModNotificacion != null &&
                (TipoModNotificacion.CodigoValor == MedioEnvioSms || TipoModNotificacion.CodigoValor == MedioEnvioCorreo);

            IsEnabledImportarExcel = EsProgramacionExcel && modalidadValida;
            IsEnabledContinuarExcel = EsProgramacionExcel && _mostrarObservadosExcel && CantidadValidosImportadosExcel > 0;

            if (EsProgramacionMasiva)
            {
                IsEnabledGuardar = true;
                return;
            }

            IsEnabledGuardar = !_mostrarObservadosExcel && _validacionMedioExcelCompleta && modalidadValida &&
                _listaCreditosValidadosExcel != null && _listaCreditosValidadosExcel.Any() &&
                (!EsMedioSmsExcel || !EsSpeechManualExcel || CantidadSpeechPendientesExcel == 0);
        }

        private async void OnSeleccionarModalidadExcel(ConstanteDto modalidad)
        {
            if (_reiniciandoProgramacionExcel)
            {
                _tipoModNotificacion = modalidad;
                OnPropertyChanged(() => TipoModNotificacion);
                return;
            }

            int anterior = _tipoModNotificacion != null ? _tipoModNotificacion.CodigoValor : 0;
            int actual = modalidad != null ? modalidad.CodigoValor : 0;
            if (anterior == actual)
            {
                return;
            }

            if (modalidad != null && (!PuedeCambiarSeleccionActual || (actual != MedioEnvioSms && actual != MedioEnvioCorreo)))
            {
                OnPropertyChanged(() => TipoModNotificacion);
                return;
            }

            if (modalidad == null || !OnTieneCargaProgramacionExcel())
            {
                _tipoModNotificacion = modalidad;
                OnLimpiarFechasProgramacion();
                EsMedioSmsExcel = actual == MedioEnvioSms;
                OnPropertyChanged(() => TipoModNotificacion);
                VisibilidadModoSpeechExcel = VisibilidadValidadosExcel == Visibility.Visible &&
                    _validacionMedioExcelCompleta && EsMedioSmsExcel ? Visibility.Visible : Visibility.Collapsed;
                VisibilidadSpeechPendientesExcel = EsMedioSmsExcel && EsSpeechManualExcel && CantidadValidosImportadosExcel > 0
                    ? Visibility.Visible : Visibility.Collapsed;
                IsEnabledCalendario = !(EsMedioSmsExcel && EsSpeechManualExcel);
                OnActualizarResumenExcel();
                OnHabilitarBotonesExcel();
                ActualizarCalendarioExcel?.Invoke(this, EventArgs.Empty);
                return;
            }

            var modalidadAnterior = _tipoModNotificacion;
            string rutaArchivo = RutaArchivoExcel;
            int version = _versionProgramacionExcel;
            ProgramacionNotificacionCobranzaModel resultado = null;
            List<ProgramacionNotificacionCobranzaEspecificoModel> observadosFormato = null;
            Exception errorProceso = null;

            try
            {
                var filasActuales = (_listaCreditosValidadosExcel ?? new ObservableCollection<ProgramacionNotificacionCobranzaExcelModel>())
                    .Concat(_listaProgramacionesExcel ?? new ObservableCollection<ProgramacionNotificacionCobranzaExcelModel>())
                    .Where(x => x != null && x.Credito != null)
                    .Select(x => x.Credito)
                    .ToList();

                var creditosRevalidar = filasActuales
                    .Where(x => EsCodigoCreditoExcelValido(x.cCtaCod))
                    .Select(x => new ProgramacionNotificacionCobranzaEspecificoModel { cCtaCod = x.cCtaCod }).ToList();

                observadosFormato = filasActuales.Where(x => !EsCodigoCreditoExcelValido(x.cCtaCod)).ToList();

                _tipoModNotificacion = modalidad;
                OnPropertyChanged(() => TipoModNotificacion);

                BusyContent = "Revalidando créditos...";
                IsBusy = true;

                if (creditosRevalidar.Any())
                {
                    resultado = await Task.Run(() => OnValidarCreditosProgramacionExcel(creditosRevalidar, actual));
                }
                else
                {
                    resultado = new ProgramacionNotificacionCobranzaModel
                    {
                        ListaCreditosEspecificos = new List<ProgramacionNotificacionCobranzaEspecificoModel>()
                    };
                }
            }
            catch (Exception ex)
            {
                errorProceso = ex;
            }
            finally
            {
                IsBusy = false;
                BusyContent = "Espere un momento por favor...";
            }

            if (version != _versionProgramacionExcel || !EsProgramacionExcel)
            {
                return;
            }

            if (errorProceso != null)
            {
                _tipoModNotificacion = modalidadAnterior;
                OnPropertyChanged(() => TipoModNotificacion);
                OnHabilitarBotonesExcel();
                ManejoErrores(errorProceso, "No se pudo revalidar la lista de créditos.");
                return;
            }

            try
            {
                resultado.ListaCreditosEspecificos.AddRange(observadosFormato ?? new List<ProgramacionNotificacionCobranzaEspecificoModel>());

                OnAplicarResultadoValidacionExcel(resultado, rutaArchivo);

                string mensaje = CantidadValidosImportadosExcel == 0
                    ? "No hay créditos válidos para la modalidad seleccionada. Revise los observados."
                    : CantidadObservadosImportadosExcel > 0
                        ? "La lista se revalidó. Revise los observados."
                        : "La lista se revalidó correctamente.";

                _messagingService.ShowMessage(mensaje, "Aviso", DialogType.Message);
            }
            catch (Exception ex)
            {
                _tipoModNotificacion = modalidadAnterior;
                OnPropertyChanged(() => TipoModNotificacion);
                OnHabilitarBotonesExcel();
                ManejoErrores(ex, "No se pudo aplicar la revalidación de créditos.");
            }
        }

        private void OnCambiarModoProgramacion(bool porExcel, bool confirmar)
        {
            if (_listaModNotificacionMasiva == null || _esProgramacionExcel == porExcel)
            {
                return;
            }

            if (!PuedeCambiarSeleccionActual)
            {
                OnPropertyChanged(() => EsProgramacionExcel);
                OnPropertyChanged(() => EsProgramacionMasiva);
                return;
            }

            bool tieneDatos = EsProgramacionExcel ? OnTieneCargaProgramacionExcel() :
                TipoModNotificacion != null || TipoPersoneria != null ||
                (FechasSeleccionadas != null && FechasSeleccionadas.Any());

            if (confirmar && tieneDatos &&
                !OnConfirmarAccionExcel("Al cambiar la selección se limpiará la programación. ¿Desea continuar?"))
            {
                OnPropertyChanged(() => EsProgramacionExcel);
                OnPropertyChanged(() => EsProgramacionMasiva);
                return;
            }

            _reiniciandoProgramacionExcel = true;
            try
            {
                OnLimpiar();
                _esProgramacionExcel = porExcel;
                ListaModNotificacion = new ObservableCollection<ConstanteDto>(porExcel
                    ? _listaModNotificacionMasiva.Where(x => x.CodigoValor == MedioEnvioSms || x.CodigoValor == MedioEnvioCorreo)
                    : _listaModNotificacionMasiva);
                VisibilidadProgramacionMasiva = porExcel ? Visibility.Collapsed : Visibility.Visible;
                VisibilidadProgramacionExcel = porExcel ? Visibility.Visible : Visibility.Collapsed;
                VisibilidadGuardar = porExcel ? Visibility.Collapsed : Visibility.Visible;
                IsEnabledGuardar = !porExcel;
            }
            finally
            {
                _reiniciandoProgramacionExcel = false;
                OnPropertyChanged(() => EsProgramacionExcel);
                OnPropertyChanged(() => EsProgramacionMasiva);
            }
        }

        private void OnCambiarModoSpeechExcel(bool manual)
        {
            if (!EsProgramacionExcel || !EsMedioSmsExcel || !PuedeCambiarSeleccionActual ||
                _esSpeechManualExcel == manual)
            {
                OnPropertyChanged(() => EsSpeechAutomaticoExcel);
                OnPropertyChanged(() => EsSpeechManualExcel);
                return;
            }

            _versionProgramacionExcel++;
            _esSpeechManualExcel = manual;
            _esSpeechAutomaticoExcel = !manual;
            OnLimpiarFechasProgramacion();
            OnSuscribirCambiosCreditosExcel(false);
            try
            {
                if (_listaCreditosValidadosExcel != null)
                {
                    foreach (var fila in _listaCreditosValidadosExcel)
                    {
                        fila.SpeechSeleccionado = manual
                            ? fila.ListaSpeechDisponibles.FirstOrDefault()
                            : OnObtenerSpeechInicialDinamicoExcel(fila.Credito);
                    }
                }
            }
            finally
            {
                OnSuscribirCambiosCreditosExcel(true);
            }

            IsEnabledCalendario = !manual;
            VisibilidadSpeechPendientesExcel = manual && CantidadValidosImportadosExcel > 0
                ? Visibility.Visible : Visibility.Collapsed;
            if (manual)
            {
                FechasSeleccionadas.Add(DateTime.Today);
            }

            OnActualizarResumenExcel();
            OnHabilitarBotonesExcel();
            OnPropertyChanged(() => EsSpeechAutomaticoExcel);
            OnPropertyChanged(() => EsSpeechManualExcel);
            ActualizarCalendarioExcel?.Invoke(this, EventArgs.Empty);
        }

        private async void OnDescargarPlantillaExcel()
        {
            if (!EsProgramacionExcel || !PuedeCambiarSeleccionActual)
            {
                return;
            }

            using (SaveFileDialog dialog = new SaveFileDialog())
            {
                dialog.Filter = @"Archivos de Excel (*.xlsx)|*.xlsx";
                dialog.Title = @"Guardar como";
                dialog.FileName = "PlantillaNotificacionEspecifica.xlsx";
                dialog.AddExtension = true;
                dialog.DefaultExt = "xlsx";
                dialog.OverwritePrompt = true;

                if (dialog.ShowDialog() != DialogResult.OK)
                {
                    return;
                }

                string rutaPlantilla = dialog.FileName;
                Exception errorProceso = null;
                string mensajeArchivo = string.Empty;

                try
                {
                    BusyContent = "Generando plantilla...";
                    IsBusy = true;

                    await Task.Run(() =>
                    {
                        using (var xlPackage = new ExcelPackage())
                        {
                            xlPackage.Workbook.Properties.Title = "PlantillaNotificacionEspecifica";
                            var ws1 = xlPackage.Workbook.Worksheets.Add(NombreHojaProgramacionExcel);

                            ws1.Cells[1, 1].Value = NombreColumnaCreditoExcel;
                            ws1.Cells[1, 1].Style.Font.Bold = true;
                            ws1.Column(1).Width = 25;
                            ws1.Column(1).Style.Numberformat.Format = "@";

                            File.WriteAllBytes(
                                rutaPlantilla,
                                xlPackage.GetAsByteArray());
                        }
                    });
                }
                catch (IOException ex)
                {
                    mensajeArchivo = EsArchivoEnUsoExcel(ex)
                        ? "El archivo está en uso. Ciérrelo y vuelva a intentarlo."
                        : "No se pudo guardar la plantilla. Elija otra ubicación.";
                }
                catch (UnauthorizedAccessException)
                {
                    mensajeArchivo = "No se pudo guardar la plantilla. Elija otra ubicación.";
                }
                catch (Exception ex)
                {
                    errorProceso = ex;
                }
                finally
                {
                    IsBusy = false;
                    BusyContent = "Espere un momento por favor...";
                }

                if (!string.IsNullOrWhiteSpace(mensajeArchivo))
                {
                    _messagingService.ShowMessage(mensajeArchivo, "Aviso", DialogType.Message);
                    return;
                }

                if (errorProceso != null)
                {
                    ManejoErrores(errorProceso, "No se pudo generar la plantilla.");
                    return;
                }

                var respuestaAbrir =
                    _messagingService.ShowMessage(
                        "Plantilla descargada. ¿Desea abrirla?",
                        "Plantilla",
                        DialogType.Question);

                if (respuestaAbrir == DialogResponse.Yes)
                {
                    try
                    {
                        System.Diagnostics.Process.Start(
                            new System.Diagnostics.ProcessStartInfo(
                                rutaPlantilla)
                            {
                                UseShellExecute = true
                            });
                    }
                    catch (Exception)
                    {
                        _messagingService.ShowMessage(
                            "No se pudo abrir la plantilla.",
                            "Aviso",
                            DialogType.Message);
                    }
                }
            }
        }

        private async void OnImportarExcel()
        {
            if (!EsProgramacionExcel || !PuedeCambiarSeleccionActual)
            {
                return;
            }

            if (TipoModNotificacion == null ||
                (TipoModNotificacion.CodigoValor != MedioEnvioSms && TipoModNotificacion.CodigoValor != MedioEnvioCorreo))
            {
                _messagingService.ShowMessage("Seleccione una modalidad.", "Aviso", DialogType.Message);
                return;
            }

            string rutaSeleccionada;
            using (var dialog = new OpenFileDialog
            {
                Filter = @"Archivos de Excel (*.xlsx)|*.xlsx",
                Title = @"Seleccione el archivo de Excel",
                FileName = string.Empty,
                Multiselect = false,
                CheckFileExists = true
            })
            {
                if (dialog.ShowDialog() != DialogResult.OK)
                {
                    return;
                }
                rutaSeleccionada = dialog.FileName;
            }

            if (OnTieneCargaProgramacionExcel() &&
                !OnConfirmarAccionExcel("Se reemplazará la lista actual. ¿Desea continuar?"))
            {
                return;
            }

            int medioEnvio = TipoModNotificacion.CodigoValor;
            int version = _versionProgramacionExcel;
            List<ProgramacionNotificacionCobranzaEspecificoModel> listaCreditos = null;
            List<ProgramacionNotificacionCobranzaEspecificoModel> observadosFormato = null;
            ProgramacionNotificacionCobranzaModel resultado = null;
            int cantidadRepetidos = 0;
            string mensajeValidacion = string.Empty;
            Exception errorProceso = null;

            try
            {
                BusyContent = "Importando y validando créditos...";
                IsBusy = true;
                listaCreditos = await Task.Run(() => OnLimpiarCreditosImportadosExcel(
                    OnLeerCreditosExcel(rutaSeleccionada), out observadosFormato, out cantidadRepetidos));

                if (listaCreditos.Any())
                {
                    resultado = await Task.Run(() => OnValidarCreditosProgramacionExcel(listaCreditos, medioEnvio));
                }
                else if (observadosFormato.Any())
                {
                    resultado = new ProgramacionNotificacionCobranzaModel
                    {
                        ListaCreditosEspecificos = new List<ProgramacionNotificacionCobranzaEspecificoModel>()
                    };
                }
                else
                {
                    mensajeValidacion = "El archivo no contiene créditos para importar.";
                }
            }
            catch (InvalidDataException ex)
            {
                mensajeValidacion = ex.Message;
            }
            catch (FileNotFoundException)
            {
                mensajeValidacion = "No se encontró el archivo. Selecciónelo nuevamente.";
            }
            catch (DirectoryNotFoundException)
            {
                mensajeValidacion = "No se encontró el archivo. Selecciónelo nuevamente.";
            }
            catch (UnauthorizedAccessException)
            {
                mensajeValidacion = "No se pudo abrir el archivo. Guárdelo en otra carpeta.";
            }
            catch (IOException ex)
            {
                mensajeValidacion = EsArchivoEnUsoExcel(ex)
                    ? "El archivo está en uso. Ciérrelo y vuelva a intentarlo."
                    : "No se pudo abrir el archivo. Vuelva a intentarlo.";
            }
            catch (Exception ex)
            {
                errorProceso = ex;
            }
            finally
            {
                IsBusy = false;
                BusyContent = "Espere un momento por favor...";
            }

            if (version != _versionProgramacionExcel || !EsProgramacionExcel ||
                TipoModNotificacion == null || TipoModNotificacion.CodigoValor != medioEnvio)
            {
                return;
            }

            if (errorProceso != null)
            {
                ManejoErrores(errorProceso, "No se pudo validar la lista de créditos.");
                return;
            }
            if (!string.IsNullOrWhiteSpace(mensajeValidacion))
            {
                _messagingService.ShowMessage(mensajeValidacion, "Aviso", DialogType.Message);
                return;
            }

            try
            {
                resultado.ListaCreditosEspecificos.AddRange(observadosFormato);
                OnAplicarResultadoValidacionExcel(resultado, rutaSeleccionada);
                string mensaje = CantidadValidosImportadosExcel == 0
                    ? "No hay créditos válidos. Revise los observados."
                    : CantidadObservadosImportadosExcel > 0
                        ? "La lista se cargó. Revise los observados."
                        : "La lista se cargó correctamente.";
                if (cantidadRepetidos > 0)
                {
                    mensaje = (cantidadRepetidos == 1 ? "Se ignoró 1 crédito repetido." :
                        string.Format("Se ignoraron {0} créditos repetidos.", cantidadRepetidos)) +
                        Environment.NewLine + mensaje;
                }
                _messagingService.ShowMessage(mensaje, "Aviso", DialogType.Message);
            }
            catch (Exception ex)
            {
                ManejoErrores(ex, "No se pudo cargar la lista de créditos.");
            }
        }

        private List<ProgramacionNotificacionCobranzaEspecificoModel> OnLeerCreditosExcel(string rutaArchivo)
        {
            if (string.IsNullOrWhiteSpace(rutaArchivo) ||
                !string.Equals(Path.GetExtension(rutaArchivo), ".xlsx", StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException("Seleccione un archivo de Excel (.xlsx).");
            }

            using (var archivo = new FileStream(rutaArchivo, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                try
                {
                    using (var libro = new ExcelPackage(archivo))
                    {
                        ExcelWorksheet hojaCreditos = null;
                        int filaCabecera = 0;
                        int columnaCredito = 0;

                        foreach (var hoja in libro.Workbook.Worksheets)
                        {
                            if (hoja.Dimension == null)
                            {
                                continue;
                            }

                            int primeraFila = int.MaxValue;
                            int columnaEncontrada = 0;
                            int coincidencias = 0;
                            foreach (var celda in hoja.Cells[hoja.Dimension.Address])
                            {
                                if (!(celda.Value is string) || !string.IsNullOrWhiteSpace(celda.Formula) ||
                                    !string.Equals(OnNormalizarCabeceraExcel((string)celda.Value),
                                    NombreColumnaCreditoExcel, StringComparison.OrdinalIgnoreCase))
                                {
                                    continue;
                                }

                                if (celda.Start.Row < primeraFila)
                                {
                                    primeraFila = celda.Start.Row;
                                    columnaEncontrada = celda.Start.Column;
                                    coincidencias = 1;
                                }
                                else if (celda.Start.Row == primeraFila)
                                {
                                    coincidencias++;
                                }
                            }

                            if (coincidencias == 0)
                            {
                                continue;
                            }
                            if (coincidencias > 1)
                            {
                                throw new InvalidDataException("Hay más de una columna cCtaCod. Deje solo una.");
                            }
                            if (hojaCreditos != null)
                            {
                                throw new InvalidDataException("Deje una sola hoja con la columna cCtaCod.");
                            }

                            hojaCreditos = hoja;
                            filaCabecera = primeraFila;
                            columnaCredito = columnaEncontrada;
                        }

                        if (hojaCreditos == null)
                        {
                            throw new InvalidDataException("El archivo debe incluir la columna cCtaCod.");
                        }

                        var creditos = new List<ProgramacionNotificacionCobranzaEspecificoModel>();
                        if (filaCabecera >= hojaCreditos.Dimension.End.Row)
                        {
                            return creditos;
                        }

                        foreach (var celda in hojaCreditos.Cells[filaCabecera + 1, columnaCredito,
                            hojaCreditos.Dimension.End.Row, columnaCredito])
                        {
                            bool tieneFormula = !string.IsNullOrWhiteSpace(celda.Formula);
                            string codigo = Convert.ToString(celda.Value, System.Globalization.CultureInfo.InvariantCulture);
                            if (string.IsNullOrWhiteSpace(codigo) && !tieneFormula)
                            {
                                continue;
                            }

                            bool esTexto = celda.Value is string && !tieneFormula;
                            creditos.Add(new ProgramacionNotificacionCobranzaEspecificoModel
                            {
                                cCtaCod = string.IsNullOrWhiteSpace(codigo) ? celda.Formula : codigo,
                                bObservado = !esTexto,
                                cObservacion = esTexto ? string.Empty : "El crédito debe estar en formato texto."
                            });
                        }
                        return creditos;
                    }
                }
                catch (InvalidDataException)
                {
                    throw;
                }
                catch (IOException)
                {
                    throw;
                }
                catch (UnauthorizedAccessException)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    throw new InvalidDataException("No se pudo leer el archivo. Revise que sea un Excel válido.", ex);
                }
            }
        }

        private string OnNormalizarCabeceraExcel(string cabecera)
        {
            return (cabecera ?? string.Empty).Trim().Trim('\uFEFF').Trim();
        }

        private bool EsCodigoCreditoExcelValido(string codigo)
        {
            return !string.IsNullOrWhiteSpace(codigo) &&
                codigo.Length == LongitudCodigoCreditoExcel &&
                codigo.All(c => c >= '0' && c <= '9');
        }

        private bool EsArchivoEnUsoExcel(IOException error)
        {
            int codigo = error.HResult & 0xFFFF;
            return codigo == 32 || codigo == 33;
        }

        private List<ProgramacionNotificacionCobranzaEspecificoModel> OnLimpiarCreditosImportadosExcel(
            List<ProgramacionNotificacionCobranzaEspecificoModel> listaCreditos,
            out List<ProgramacionNotificacionCobranzaEspecificoModel> observadosFormato,
            out int cantidadRepetidos)
        {
            var creditos = (listaCreditos ?? new List<ProgramacionNotificacionCobranzaEspecificoModel>())
                .Where(x => x != null && !string.IsNullOrWhiteSpace(x.cCtaCod))
                .ToList();

            foreach (var credito in creditos)
            {
                credito.cCtaCod = credito.cCtaCod.Trim();

                if (!credito.bObservado &&
                    !EsCodigoCreditoExcelValido(credito.cCtaCod))
                {
                    credito.bObservado = true;
                    credito.cObservacion = "El crédito debe tener 18 dígitos.";
                }
            }

            var gruposCreditos = creditos.GroupBy(x => x.cCtaCod, StringComparer.Ordinal).ToList();

            cantidadRepetidos = creditos.Count - gruposCreditos.Count;

            var creditosUnicos = gruposCreditos.Select(x => x.FirstOrDefault(y => !y.bObservado) ?? x.First()).ToList();

            observadosFormato = creditosUnicos.Where(x => x.bObservado).OrderBy(x => x.cCtaCod, StringComparer.Ordinal).ToList();

            return creditosUnicos.Where(x => !x.bObservado).ToList();
        }

        private ProgramacionNotificacionCobranzaModel OnValidarCreditosProgramacionExcel(IEnumerable<ProgramacionNotificacionCobranzaEspecificoModel> creditos, int medioEnvio)
        {
            var lista = (creditos ?? new List<ProgramacionNotificacionCobranzaEspecificoModel>()).ToList();

            var codigos = new HashSet<string>(lista.Select(x => x.cCtaCod), StringComparer.Ordinal);
            var entiModel = new ProgramacionNotificacionCobranzaModel();
            entiModel.TipoModNotiCodVal = medioEnvio;
            entiModel.ListaCreditosEspecificos = lista.Select(x => new ProgramacionNotificacionCobranzaEspecificoModel { cCtaCod = x.cCtaCod }).ToList();

            var resultado = _programacionCobranzaNotifDataClient.ValidarCreditosEspecificos(entiModel);
            if (resultado == null || resultado.ListaCreditosEspecificos == null ||
                resultado.ListaCreditosEspecificos.Count != lista.Count)
            {
                throw new InvalidOperationException("No se pudo validar toda la lista de créditos.");
            }

            foreach (var credito in resultado.ListaCreditosEspecificos)
            {
                if (credito == null || !codigos.Remove(credito.cCtaCod))
                {
                    throw new InvalidOperationException("No se pudo validar toda la lista de créditos.");
                }
            }

            if (codigos.Any())
            {
                throw new InvalidOperationException("No se pudo validar toda la lista de créditos.");
            }

            return resultado;
        }

        private void OnAplicarResultadoValidacionExcel(ProgramacionNotificacionCobranzaModel resultado, string rutaArchivo)
        {
            if (resultado == null ||
                resultado.ListaCreditosEspecificos == null)
            {
                throw new InvalidOperationException("No se pudo completar la validación de créditos.");
            }

            var creditos = resultado.ListaCreditosEspecificos.OrderBy(x => x.nTipoPersona ?? int.MaxValue).ThenBy(x => x.cCtaCod, StringComparer.Ordinal).ToList();

            var filasValidas = new ObservableCollection<ProgramacionNotificacionCobranzaExcelModel>(creditos.Where(x => !x.bObservado).Select(OnCrearFilaProgramacionExcel));

            var filasObservadas = new ObservableCollection<ProgramacionNotificacionCobranzaExcelModel>(creditos.Where(x => x.bObservado).Select(OnCrearFilaProgramacionExcel));

            OnSuscribirCambiosCreditosExcel(false);

            _versionProgramacionExcel++;
            _listaCreditosValidadosExcel = filasValidas;
            _listaProgramacionesExcel = filasObservadas;

            OnSuscribirCambiosCreditosExcel(true);

            _tipoModNotificacionExcel = TipoModNotificacion;
            _validacionMedioExcelCompleta = true;
            _mostrarObservadosExcel = filasObservadas.Any();
            if (EsMedioSmsExcel && EsSpeechManualExcel)
            {
                // La nueva carga vuelve a speech automatico y deja la seleccion de fechas disponible.
                OnLimpiarFechasProgramacion();
            }
            EsMedioSmsExcel = TipoModNotificacion != null && TipoModNotificacion.CodigoValor == MedioEnvioSms;
            _esSpeechAutomaticoExcel = true;
            _esSpeechManualExcel = false;

            RutaArchivoExcel = rutaArchivo;
            PaginaActualExcel = 1;

            OnActualizarResumenExcel();
            OnActualizarPaginacionExcel();
            VisibilidadObservadosExcel = _mostrarObservadosExcel ? Visibility.Visible : Visibility.Collapsed;
            VisibilidadValidadosExcel = !_mostrarObservadosExcel && CantidadValidosImportadosExcel > 0  ? Visibility.Visible : Visibility.Collapsed;
            VisibilidadGuardar = VisibilidadValidadosExcel;
            VisibilidadModoSpeechExcel = VisibilidadValidadosExcel == Visibility.Visible && EsMedioSmsExcel ? Visibility.Visible : Visibility.Collapsed;
            VisibilidadSpeechPendientesExcel = Visibility.Collapsed;
            IsEnabledCalendario = true;
            IsEnabledHorario = !_mostrarObservadosExcel && CantidadValidosImportadosExcel > 0;
            OnHabilitarBotonesExcel();
            OnPropertyChanged(() => EsSpeechAutomaticoExcel);
            OnPropertyChanged(() => EsSpeechManualExcel);
            ActualizarCalendarioExcel?.Invoke(this, EventArgs.Empty);
        }

        private ProgramacionNotificacionCobranzaExcelModel OnCrearFilaProgramacionExcel(
            ProgramacionNotificacionCobranzaEspecificoModel credito)
        {
            return new ProgramacionNotificacionCobranzaExcelModel
            {
                Credito = credito,
                ListaSpeechDisponibles = OnObtenerSpeechProgramacionExcel(credito),
                SpeechSeleccionado = OnObtenerSpeechInicialDinamicoExcel(credito)
            };
        }

        private ConstanteDto OnObtenerSpeechInicialDinamicoExcel(
            ProgramacionNotificacionCobranzaEspecificoModel credito)
        {
            if (credito == null || credito.bObservado || ListaSpeech == null || !credito.nDiasAtraso.HasValue)
            {
                return null;
            }

            int codigoSpeech;
            int diasAtraso = credito.nDiasAtraso.Value;

            if (credito.nTipoPersona == 1)
            {
                if (credito.bEsHonradoOProgramaGobierno)
                {
                    codigoSpeech = 7;
                }
                else if (diasAtraso == 0)
                {
                    codigoSpeech = 1;
                }
                else if (diasAtraso > 0)
                {
                    codigoSpeech = 2;
                }
                else
                {
                    codigoSpeech = 5;
                }
            }
            else if (credito.nTipoPersona == 2)
            {
                if (credito.bEsHonradoOProgramaGobierno)
                {
                    codigoSpeech = 8;
                }
                else if (diasAtraso == 0)
                {
                    codigoSpeech = 3;
                }
                else if (diasAtraso > 0)
                {
                    codigoSpeech = 4;
                }
                else
                {
                    codigoSpeech = 6;
                }
            }
            else
            {
                return null;
            }

            return ListaSpeech.FirstOrDefault(x =>
                x.CodigoValor == codigoSpeech);
        }

        private ObservableCollection<ConstanteDto> OnObtenerSpeechProgramacionExcel(
            ProgramacionNotificacionCobranzaEspecificoModel credito)
        {
            if (credito == null || credito.bObservado || ListaSpeech == null ||
                !credito.nDiasAtraso.HasValue)
            {
                return new ObservableCollection<ConstanteDto>();
            }

            var codigosSpeech = new List<int>();
            int diasAtraso = credito.nDiasAtraso.Value;

            if (credito.nTipoPersona == 1)
            {
                if (diasAtraso < 0)
                {
                    codigosSpeech.AddRange(new[] { 9, 5 });
                }
                else if (diasAtraso == 0)
                {
                    codigosSpeech.AddRange(new[] { 11, 1 });

                    if (credito.bEsHonradoOProgramaGobierno)
                    {
                        codigosSpeech.Add(7);
                    }
                }
                else if (diasAtraso <= 30)
                {
                    codigosSpeech.AddRange(new[] { 13, 15, 2 });

                    if (credito.bEsHonradoOProgramaGobierno)
                    {
                        codigosSpeech.Add(7);
                    }
                }
                else
                {
                    codigosSpeech.AddRange(new[] { 17, 2 });

                    if (credito.bEsHonradoOProgramaGobierno)
                    {
                        codigosSpeech.Add(7);
                    }
                }
            }
            else if (credito.nTipoPersona == 2)
            {
                if (diasAtraso < 0)
                {
                    codigosSpeech.AddRange(new[] { 10, 6 });
                }
                else if (diasAtraso == 0)
                {
                    codigosSpeech.AddRange(new[] { 12, 3 });

                    if (credito.bEsHonradoOProgramaGobierno)
                    {
                        codigosSpeech.Add(8);
                    }
                }
                else if (diasAtraso <= 30)
                {
                    codigosSpeech.AddRange(new[] { 14, 16, 4 });

                    if (credito.bEsHonradoOProgramaGobierno)
                    {
                        codigosSpeech.Add(8);
                    }
                }
                else
                {
                    codigosSpeech.AddRange(new[] { 18, 4 });

                    if (credito.bEsHonradoOProgramaGobierno)
                    {
                        codigosSpeech.Add(8);
                    }
                }
            }

            return new ObservableCollection<ConstanteDto>(
                codigosSpeech
                    .Distinct()
                    .Select(codigo => ListaSpeech.FirstOrDefault(x => x.CodigoValor == codigo))
                    .Where(x => x != null));
        }

        private void OnEliminarCreditoExcel(
            ProgramacionNotificacionCobranzaExcelModel credito)
        {
            if (!PuedeCambiarSeleccionActual || !EsProgramacionExcel || _mostrarObservadosExcel ||
                credito == null || credito.Credito == null || _listaCreditosValidadosExcel == null ||
                !_listaCreditosValidadosExcel.Contains(credito))
            {
                return;
            }

            if (!OnConfirmarAccionExcel(string.Format(
                "¿Desea eliminar el crédito {0}?", credito.Credito.cCtaCod)))
            {
                return;
            }

            _versionProgramacionExcel++;
            credito.PropertyChanged -= CreditoExcel_PropertyChanged;
            _listaCreditosValidadosExcel.Remove(credito);
            if (!_listaCreditosValidadosExcel.Any())
            {
                OnLimpiar();
                return;
            }
            OnActualizarResumenExcel();
            OnActualizarPaginacionExcel();
            OnHabilitarBotonesExcel();
        }

        private void OnContinuarExcel()
        {
            if (!IsEnabledContinuarExcel || !PuedeCambiarSeleccionActual)
            {
                return;
            }

            _mostrarObservadosExcel = false;
            PaginaActualExcel = 1;
            OnActualizarPaginacionExcel();
            VisibilidadObservadosExcel = Visibility.Collapsed;
            VisibilidadValidadosExcel = Visibility.Visible;
            VisibilidadGuardar = Visibility.Visible;
            VisibilidadModoSpeechExcel = EsMedioSmsExcel ? Visibility.Visible : Visibility.Collapsed;
            IsEnabledHorario = _validacionMedioExcelCompleta && CantidadValidosImportadosExcel > 0;
            OnHabilitarBotonesExcel();
        }

        private void OnPaginaAnteriorExcel()
        {
            if (IsBusy || _confirmandoAccionExcel)
            {
                return;
            }

            if (PaginaActualExcel <= 1)
            {
                return;
            }

            PaginaActualExcel--;
            OnActualizarPaginacionExcel();
        }

        private void OnPaginaSiguienteExcel()
        {
            if (IsBusy || _confirmandoAccionExcel)
            {
                return;
            }

            if (PaginaActualExcel >= TotalPaginasExcel)
            {
                return;
            }

            PaginaActualExcel++;
            OnActualizarPaginacionExcel();
        }

        private void OnActualizarPaginacionExcel()
        {
            int tamanioPagina = TamanoPaginaExcel > 0 ? TamanoPaginaExcel : 10;
            var listaActual = _mostrarObservadosExcel ? _listaProgramacionesExcel : _listaCreditosValidadosExcel;
            int totalRegistros = listaActual != null ? listaActual.Count : 0;

            TotalPaginasExcel = Math.Max(1, (int)Math.Ceiling(totalRegistros / (double)tamanioPagina));
            PaginaActualExcel = Math.Max(1, Math.Min(PaginaActualExcel, TotalPaginasExcel));
            int omitir = (PaginaActualExcel - 1) * tamanioPagina;

            ListaProgramacionesExcelPagina = OnObtenerPaginaExcel(_mostrarObservadosExcel ? _listaProgramacionesExcel : null, omitir, tamanioPagina);
            ListaCreditosValidadosExcelPagina = OnObtenerPaginaExcel(!_mostrarObservadosExcel ? _listaCreditosValidadosExcel : null, omitir, tamanioPagina);
            PuedePaginaAnteriorExcel = PaginaActualExcel > 1;
            PuedePaginaSiguienteExcel = PaginaActualExcel < TotalPaginasExcel;
        }

        private ObservableCollection<ProgramacionNotificacionCobranzaExcelModel> OnObtenerPaginaExcel(
            IEnumerable<ProgramacionNotificacionCobranzaExcelModel> creditos, int omitir, int cantidad)
        {
            return new ObservableCollection<ProgramacionNotificacionCobranzaExcelModel>((creditos ?? Enumerable.Empty<ProgramacionNotificacionCobranzaExcelModel>()).Skip(omitir).Take(cantidad));
        }

        private void CreditoExcel_PropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == "SpeechSeleccionado")
            {
                OnActualizarResumenExcel();
                OnHabilitarBotonesExcel();
            }
        }

        public bool EsFechaBloqueadaExcel(DateTime fecha)
        {
            return fecha.DayOfWeek == DayOfWeek.Saturday ||
                   fecha.DayOfWeek == DayOfWeek.Sunday ||
                   (ListaFeriados != null && ListaFeriados.Any(x => x.Date == fecha.Date)) ||
                   (ListaFechasBloqueadas != null && ListaFechasBloqueadas.Any(x => x.Date == fecha.Date));
        }

        private async void OnGuardarProgramacionExcel()
        {
            if (!EsProgramacionExcel || !IsEnabledGuardar || IsBusy)
            {
                return;
            }

            Exception errorProceso = null;
            bool registroConfirmado = false;

            try
            {
                if (!_validacionMedioExcelCompleta ||
                    TipoModNotificacion == null || _tipoModNotificacionExcel == null ||
                    TipoModNotificacion.CodigoValor != _tipoModNotificacionExcel.CodigoValor ||
                    (TipoModNotificacion.CodigoValor != MedioEnvioSms &&
                     TipoModNotificacion.CodigoValor != MedioEnvioCorreo))
                {
                    _messagingService.ShowMessage("Importe los créditos antes de guardar.", "Aviso", DialogType.Message);
                    return;
                }

                var filas = (_listaCreditosValidadosExcel ?? new ObservableCollection<ProgramacionNotificacionCobranzaExcelModel>()).ToList();
                if (!filas.Any())
                {
                    _messagingService.ShowMessage("No hay créditos válidos para programar.", "Aviso", DialogType.Message);
                    return;
                }

                if (filas.Any(x => x == null || x.Credito == null || x.Credito.bObservado ||
                    !EsCodigoCreditoExcelValido(x.Credito.cCtaCod)) ||
                    filas.Select(x => x.Credito.cCtaCod).Distinct(StringComparer.Ordinal).Count() != filas.Count)
                {
                    _messagingService.ShowMessage("La lista no está completa. Vuelva a importar el archivo.", "Aviso", DialogType.Message);
                    return;
                }

                bool esManual = EsMedioSmsExcel && EsSpeechManualExcel;
                if (esManual && CantidadSpeechPendientesExcel > 0)
                {
                    _messagingService.ShowMessage("Seleccione un mensaje para cada crédito.", "Aviso", DialogType.Message);
                    return;
                }

                if (HoraProgramada > maxHora)
                {
                    _messagingService.ShowMessage(String.Format("Debe ingresar una hora menor a 20:00 hrs"), "Mensaje informativo", DialogType.Message);
                    return;
                }

                if (!esManual && (FechasSeleccionadas == null || !FechasSeleccionadas.Any()))
                {
                    _messagingService.ShowMessage("Seleccione una o más fechas.", "Aviso", DialogType.Message);
                    return;
                }

                if (!OnConfirmarAccionExcel(string.Format(
                    "¿Desea programar {0} créditos?", filas.Count)))
                {
                    return;
                }

                DateTime fechaReferencia = DateTime.Today;
                if (esManual)
                {
                    FechasSeleccionadas = new ObservableCollection<DateTime>() { fechaReferencia };
                    ActualizarCalendarioExcel?.Invoke(this, EventArgs.Empty);
                }
                var fechas = esManual
                    ? new List<DateTime> { fechaReferencia }
                    : FechasSeleccionadas.Select(x => x.Date).Distinct().ToList();

                if (esManual && EsFechaBloqueadaExcel(fechaReferencia))
                {
                    _messagingService.ShowMessage("Hoy no está disponible para programar.", "Aviso", DialogType.Message);
                    return;
                }

                if (fechas.Any(x => x < fechaReferencia || EsFechaBloqueadaExcel(x)))
                {
                    _messagingService.ShowMessage("Seleccione fechas disponibles desde hoy.", "Aviso", DialogType.Message);
                    return;
                }

                var fechasHoras = new ObservableCollection<DateTime>(
                    fechas.Select(x => x + HoraProgramada));
                if (fechasHoras.Any(x => x < DateTime.Now.Add(minRestriccion)))
                {
                    _messagingService.ShowMessage("Programe con al menos 10 minutos de anticipación.", "Aviso", DialogType.Message);
                    return;
                }

                var entiModel = new ProgramacionNotificacionCobranzaModel();
                entiModel.TipoModNotiCodVal = TipoModNotificacion.CodigoValor;
                entiModel.cUsuario = VariablesGlobales.DatosSesion.cNombreUsuario;
                entiModel.FechasSeleccionadas = fechasHoras;
                entiModel.ListaCreditosEspecificos = filas
                    .Select(x => new ProgramacionNotificacionCobranzaEspecificoModel
                    {
                        cCtaCod = x.Credito.cCtaCod,
                        cSpeech = esManual ? x.SpeechSeleccionado.Descripcion : null
                    })
                    .ToList();

                BusyContent = "Guardando programación...";
                IsBusy = true;

                var resultado = await Task.Run(() => _programacionCobranzaNotifDataClient.RegistrarProgramacionNotificacionCobranzaEspecifica(entiModel));
                if (resultado == null)
                {
                    throw new InvalidOperationException("No se recibió la confirmación del registro.");
                }

                registroConfirmado = true;
            }
            catch (Exception ex)
            {
                errorProceso = ex;
            }
            finally
            {
                IsBusy = false;
                BusyContent = "Espere un momento por favor...";
            }

            if (errorProceso != null)
            {
                ManejoErrores(errorProceso, "No se pudo confirmar el registro. Revise las programaciones antes de intentarlo nuevamente.");
                return;
            }

            if (registroConfirmado)
            {
                _messagingService.ShowMessage("La programación se registró correctamente.", "Aviso", DialogType.Message);
                try
                {
                    OnCambiarModoProgramacion(false, false);
                }
                catch (Exception ex)
                {
                    ManejoErrores(ex, "La programación se registró. Vuelva a abrir la ventana para continuar.");
                }
            }
        }

        private bool OnTieneCargaProgramacionExcel()
        {
            return !string.IsNullOrWhiteSpace(RutaArchivoExcel) || CantidadRegistrosUnicosImportadosExcel > 0;
        }

        #region Propiedades Programacion Especifica - Excel

        private bool _isBusy;
        public bool IsBusy
        {
            get { return _isBusy; }
            set
            {
                if (_isBusy != value)
                {
                    _isBusy = value;
                    OnPropertyChanged(() => IsBusy);
                }
            }
        }

        private string _busyContent = "Espere un momento por favor...";
        public string BusyContent
        {
            get { return _busyContent; }
            set
            {
                if (_busyContent != value)
                {
                    _busyContent = value;
                    OnPropertyChanged(() => BusyContent);
                }
            }
        }

        public bool EsProgramacionMasiva
        {
            get { return !_esProgramacionExcel; }
            set { if (value) OnCambiarModoProgramacion(false, true); }
        }

        private bool _esProgramacionExcel;
        public bool EsProgramacionExcel
        {
            get { return _esProgramacionExcel; }
            set { if (value) OnCambiarModoProgramacion(true, true); }
        }

        public bool PuedeCambiarSeleccionActual
        {
            get { return !IsBusy && !_confirmandoAccionExcel; }
        }

        private Visibility _visibilidadProgramacionMasiva;
        public Visibility VisibilidadProgramacionMasiva
        {
            get { return _visibilidadProgramacionMasiva; }
            set
            {
                if (_visibilidadProgramacionMasiva != value)
                {
                    _visibilidadProgramacionMasiva = value;
                    OnPropertyChanged(() => VisibilidadProgramacionMasiva);
                }
            }
        }

        private Visibility _visibilidadProgramacionExcel;
        public Visibility VisibilidadProgramacionExcel
        {
            get { return _visibilidadProgramacionExcel; }
            set
            {
                if (_visibilidadProgramacionExcel != value)
                {
                    _visibilidadProgramacionExcel = value;
                    OnPropertyChanged(() => VisibilidadProgramacionExcel);
                }
            }
        }

        private Visibility _visibilidadSpeechMasivo;
        public Visibility VisibilidadSpeechMasivo
        {
            get { return _visibilidadSpeechMasivo; }
            set
            {
                if (_visibilidadSpeechMasivo != value)
                {
                    _visibilidadSpeechMasivo = value;
                    OnPropertyChanged(() => VisibilidadSpeechMasivo);
                }
            }
        }

        private bool _isEnabledCalendario = true;
        public bool IsEnabledCalendario
        {
            get { return _isEnabledCalendario; }
            set
            {
                if (_isEnabledCalendario != value)
                {
                    _isEnabledCalendario = value;
                    OnPropertyChanged(() => IsEnabledCalendario);
                }
            }
        }

        private bool _isEnabledImportarExcel;
        public bool IsEnabledImportarExcel
        {
            get { return _isEnabledImportarExcel; }
            set
            {
                if (_isEnabledImportarExcel != value)
                {
                    _isEnabledImportarExcel = value;
                    OnPropertyChanged(() => IsEnabledImportarExcel);
                }
            }
        }

        private Visibility _visibilidadObservadosExcel;
        public Visibility VisibilidadObservadosExcel
        {
            get { return _visibilidadObservadosExcel; }
            set
            {
                if (_visibilidadObservadosExcel != value)
                {
                    _visibilidadObservadosExcel = value;
                    OnPropertyChanged(() => VisibilidadObservadosExcel);
                }
            }
        }

        private Visibility _visibilidadValidadosExcel;
        public Visibility VisibilidadValidadosExcel
        {
            get { return _visibilidadValidadosExcel; }
            set
            {
                if (_visibilidadValidadosExcel != value)
                {
                    _visibilidadValidadosExcel = value;
                    OnPropertyChanged(() => VisibilidadValidadosExcel);
                }
            }
        }

        private bool _isEnabledContinuarExcel;
        public bool IsEnabledContinuarExcel
        {
            get { return _isEnabledContinuarExcel; }
            set
            {
                if (_isEnabledContinuarExcel != value)
                {
                    _isEnabledContinuarExcel = value;
                    OnPropertyChanged(() => IsEnabledContinuarExcel);
                }
            }
        }

        private Visibility _visibilidadGuardar = Visibility.Visible;
        public Visibility VisibilidadGuardar
        {
            get { return _visibilidadGuardar; }
            set
            {
                if (_visibilidadGuardar != value)
                {
                    _visibilidadGuardar = value;
                    OnPropertyChanged(() => VisibilidadGuardar);
                }
            }
        }

        private string _rutaArchivoExcel;

        public string RutaArchivoExcel
        {
            get { return _rutaArchivoExcel; }
            set
            {
                if (_rutaArchivoExcel != value)
                {
                    _rutaArchivoExcel = value;
                    OnPropertyChanged(() => RutaArchivoExcel);

                }
            }
        }

        private int _cantidadRegistrosUnicosImportadosExcel;

        public int CantidadRegistrosUnicosImportadosExcel
        {
            get { return _cantidadRegistrosUnicosImportadosExcel; }
            set
            {
                if (_cantidadRegistrosUnicosImportadosExcel != value)
                {
                    _cantidadRegistrosUnicosImportadosExcel = value;
                    OnPropertyChanged(() => CantidadRegistrosUnicosImportadosExcel);
                }
            }
        }

        private int _cantidadValidosImportadosExcel;

        public int CantidadValidosImportadosExcel
        {
            get { return _cantidadValidosImportadosExcel; }
            set
            {
                if (_cantidadValidosImportadosExcel != value)
                {
                    _cantidadValidosImportadosExcel = value;
                    OnPropertyChanged(() => CantidadValidosImportadosExcel);
                }
            }
        }

        private int _cantidadObservadosImportadosExcel;

        public int CantidadObservadosImportadosExcel
        {
            get { return _cantidadObservadosImportadosExcel; }
            set
            {
                if (_cantidadObservadosImportadosExcel != value)
                {
                    _cantidadObservadosImportadosExcel = value;
                    OnPropertyChanged(() => CantidadObservadosImportadosExcel);
                }
            }
        }

        private bool _esMedioSmsExcel;
        public bool EsMedioSmsExcel
        {
            get { return _esMedioSmsExcel; }
            set
            {
                if (_esMedioSmsExcel != value)
                {
                    _esMedioSmsExcel = value;
                    OnPropertyChanged(() => EsMedioSmsExcel);
                }
            }
        }

        private Visibility _visibilidadModoSpeechExcel;
        public Visibility VisibilidadModoSpeechExcel
        {
            get { return _visibilidadModoSpeechExcel; }
            set
            {
                if (_visibilidadModoSpeechExcel != value)
                {
                    _visibilidadModoSpeechExcel = value;
                    OnPropertyChanged(() => VisibilidadModoSpeechExcel);
                }
            }
        }

        private Visibility _visibilidadSpeechPendientesExcel;
        public Visibility VisibilidadSpeechPendientesExcel
        {
            get { return _visibilidadSpeechPendientesExcel; }
            set
            {
                if (_visibilidadSpeechPendientesExcel != value)
                {
                    _visibilidadSpeechPendientesExcel = value;
                    OnPropertyChanged(() => VisibilidadSpeechPendientesExcel);
                }
            }
        }

        private ObservableCollection<ProgramacionNotificacionCobranzaExcelModel> _listaProgramacionesExcelPagina;

        public ObservableCollection<ProgramacionNotificacionCobranzaExcelModel> ListaProgramacionesExcelPagina
        {
            get { return _listaProgramacionesExcelPagina; }
            set
            {
                _listaProgramacionesExcelPagina = value;
                OnPropertyChanged(() => ListaProgramacionesExcelPagina);
            }
        }

        private ObservableCollection<ProgramacionNotificacionCobranzaExcelModel> _listaCreditosValidadosExcelPagina;

        public ObservableCollection<ProgramacionNotificacionCobranzaExcelModel> ListaCreditosValidadosExcelPagina
        {
            get { return _listaCreditosValidadosExcelPagina; }
            set
            {
                _listaCreditosValidadosExcelPagina = value;
                OnPropertyChanged(() => ListaCreditosValidadosExcelPagina);
            }
        }

        private ObservableCollection<int> _opcionesTamanoPaginaExcel;

        public ObservableCollection<int> OpcionesTamanoPaginaExcel
        {
            get { return _opcionesTamanoPaginaExcel; }
            set
            {
                _opcionesTamanoPaginaExcel = value;
                OnPropertyChanged(() => OpcionesTamanoPaginaExcel);
            }
        }

        private int _tamanoPaginaExcel = 10;
        public int TamanoPaginaExcel
        {
            get { return _tamanoPaginaExcel; }
            set
            {
                if ((value == 10 || value == 20 || value == 50) && _tamanoPaginaExcel != value)
                {
                    _tamanoPaginaExcel = value;
                    PaginaActualExcel = 1;
                    OnPropertyChanged(() => TamanoPaginaExcel);
                    OnActualizarPaginacionExcel();
                }
            }
        }

        private int _paginaActualExcel = 1;

        public int PaginaActualExcel
        {
            get { return _paginaActualExcel; }
            set
            {
                if (_paginaActualExcel != value)
                {
                    _paginaActualExcel = value;
                    OnPropertyChanged(() => PaginaActualExcel);
                }
            }
        }

        private int _totalPaginasExcel = 1;

        public int TotalPaginasExcel
        {
            get { return _totalPaginasExcel; }
            set
            {
                if (_totalPaginasExcel != value)
                {
                    _totalPaginasExcel = value;
                    OnPropertyChanged(() => TotalPaginasExcel);
                }
            }
        }

        private bool _puedePaginaAnteriorExcel;
        public bool PuedePaginaAnteriorExcel
        {
            get { return _puedePaginaAnteriorExcel; }
            set
            {
                if (_puedePaginaAnteriorExcel != value)
                {
                    _puedePaginaAnteriorExcel = value;
                    OnPropertyChanged(() => PuedePaginaAnteriorExcel);
                }
            }
        }

        private bool _puedePaginaSiguienteExcel;
        public bool PuedePaginaSiguienteExcel
        {
            get { return _puedePaginaSiguienteExcel; }
            set
            {
                if (_puedePaginaSiguienteExcel != value)
                {
                    _puedePaginaSiguienteExcel = value;
                    OnPropertyChanged(() => PuedePaginaSiguienteExcel);
                }
            }
        }

        private bool _esSpeechAutomaticoExcel = true;
        public bool EsSpeechAutomaticoExcel
        {
            get { return _esSpeechAutomaticoExcel; }
            set { if (value) OnCambiarModoSpeechExcel(false); }
        }

        private bool _esSpeechManualExcel;
        public bool EsSpeechManualExcel
        {
            get { return _esSpeechManualExcel; }
            set { if (value) OnCambiarModoSpeechExcel(true); }
        }

        private int _cantidadSpeechPendientesExcel;
        public int CantidadSpeechPendientesExcel
        {
            get { return _cantidadSpeechPendientesExcel; }
            set
            {
                if (_cantidadSpeechPendientesExcel != value)
                {
                    _cantidadSpeechPendientesExcel = value;
                    OnPropertyChanged(() => CantidadSpeechPendientesExcel);
                }
            }
        }

        private bool _isEnabledGuardar = true;
        public bool IsEnabledGuardar
        {
            get { return _isEnabledGuardar; }
            set
            {
                if (_isEnabledGuardar != value)
                {
                    _isEnabledGuardar = value;
                    OnPropertyChanged(() => IsEnabledGuardar);
                }
            }
        }

        #endregion

        #endregion

        #endregion

    }
}
