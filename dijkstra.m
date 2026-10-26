% dijkstra.m
% Parte 5 - Algoritmo de Dijkstra.
%
% Entrada:
%   A : matriz de adjacência (esparsa ou cheia) n x n com custos >= 0;
%       A(u,v) > 0 é o custo da aresta u -> v, e A(u,v) = 0 indica ausência
%       de aresta.
%   s : vértice inicial
%
% Saída:
%   dist     : dist(v) = distância mínima de s até v (Inf se inalcançável)
%   anterior : anterior(v) = predecessor de v no caminho mínimo (0 se não há)
%
% Ideia: mantém um conjunto de vértices "fechados" (distância já definitiva).
% A cada passo fecha o vértice aberto de menor distância e tenta melhorar
% (relaxar) a distância de seus vizinhos passando por ele.
function [dist, anterior] = dijkstra(A, s)
  n = rows(A);
  dist     = inf(n, 1);
  anterior = zeros(n, 1);
  fechado  = false(n, 1);

  dist(s) = 0;
  At = A.';                          % At(:,u) = linha u de A (acesso por coluna)

  for passo = 1:n
    % escolhe o vértice aberto com menor distância
    d = dist;
    d(fechado) = Inf;
    [dmin, u] = min(d);
    if isinf(dmin)
      break;                         % o resto é inalcançável
    endif
    fechado(u) = true;

    % relaxa as arestas que saem de u
    vizinhos = find(At(:, u))';
    for v = vizinhos
      if ~fechado(v)
        novo = dist(u) + At(v, u);
        if novo < dist(v)
          dist(v)     = novo;
          anterior(v) = u;
        endif
      endif
    endfor
  endfor
endfunction
