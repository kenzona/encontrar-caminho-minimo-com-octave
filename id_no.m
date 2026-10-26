% id_no.m
% Identificador inteiro da célula (i,j) de uma grade N x N:
%   id(i,j) = (i-1)*N + j
% Aceita i e j escalares ou matrizes/vetores do mesmo tamanho.
function id = id_no(i, j, N)
  id = (i - 1) * N + j;
endfunction
