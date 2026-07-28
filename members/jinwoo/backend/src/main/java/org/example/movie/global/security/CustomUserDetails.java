package org.example.movie.global.security;

import lombok.AllArgsConstructor;
import lombok.Getter;
import org.example.movie.domain.member.entity.Member;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

@Getter
@AllArgsConstructor
public class CustomUserDetails implements UserDetails {
    private final Member member;

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities(){
        return List.of();
    }

    @Override
    public String getPassword(){
        return member.getPassword();
    }
    @Override
    public String getUsername(){
        return member.getEmail();
    }
}
