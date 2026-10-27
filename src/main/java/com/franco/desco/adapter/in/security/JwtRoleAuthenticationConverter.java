package com.franco.desco.adapter.in.security;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.Collection;
import java.util.List;

@Component
public class JwtRoleAuthenticationConverter
        implements Converter<
        Jwt,
        AbstractAuthenticationToken
        > {

    @Override
    public AbstractAuthenticationToken convert(
            Jwt jwt
    ) {
        List<String> roles =
                jwt.getClaimAsStringList("roles");

        Collection<SimpleGrantedAuthority> authorities =
                roles == null
                        ? List.of()
                        : roles.stream()
                        .map(role ->
                                new SimpleGrantedAuthority(
                                        "ROLE_" + role
                                )
                        )
                        .toList();

        return new JwtAuthenticationToken(
                jwt,
                authorities,
                jwt.getClaimAsString("username")
        );
    }
}
