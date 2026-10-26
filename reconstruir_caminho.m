% reconstruir_caminho.m
% Parte 6 - Reconstrução do caminho mínimo a partir dos predecessores.
%
% Entrada:
%   anterior : vetor de predecessores devolvido pelo dijkstra
%   s, t     : vértices inicial e final
%
% Saída:
%   caminho  : vetor linha (s, v1, ..., vk, t); vazio se t não é alcançável.
%
% Partindo de t, segue t, p(t), p(p(t)), ... até chegar em s e depois
% inverte a sequência.
function caminho = reconstruir_caminho(anterior, s, t)
  caminho = t;
  v = t;
  while v ~= s
    v = anterior(v);
    if v == 0
      caminho = [];          % t não é alcançável a partir de s
      return;
    endif
    caminho(end+1) = v;
  endwhile
  caminho = fliplr(caminho);
endfunction
