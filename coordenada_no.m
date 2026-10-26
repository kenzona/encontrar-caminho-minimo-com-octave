% coordenada_no.m
% Dado o id de um (ou vários) vértice(s), devolve:
%   i, j : linha e coluna da célula na grade N x N
%   x, y : coordenadas do centro da célula na imagem (mesmos eixos do imshow:
%          x = coluna, y = linha), para uma imagem de alt x larg pixels.
%
% O labirinto de N x N células ocupa uma imagem de (2N+1) x (2N+1) "blocos":
% as paredes ficam nos blocos de índice ímpar e as células nos de índice par.
% Logo, a célula (i,j) corresponde ao bloco (2i, 2j).
function [x, y, i, j] = coordenada_no(id, N, alt, larg)
  i = floor((id - 1) / N) + 1;
  j = mod(id - 1, N) + 1;

  M = 2 * N + 1;                       % número de blocos por lado
  x = 0.5 + (2 * j - 0.5) * larg / M;  % centro do bloco 2j (horizontal)
  y = 0.5 + (2 * i - 0.5) * alt  / M;  % centro do bloco 2i (vertical)
endfunction
