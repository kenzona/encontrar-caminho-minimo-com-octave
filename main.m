% main.m
% Lista Computacional II - Do Labirinto ao Grafo: Caminho Mínimo em Imagens
%
% Arquivos utilizados:
%   main.m, id_no.m, coordenada_no.m, dijkstra.m, reconstruir_caminho.m
%
% Para rodar: coloque a imagem do labirinto na mesma pasta e execute "main".
clear; clc; close all;
pkg load image

N = 20;                        % células por lado do labirinto
arquivo = "labirinto.png";     % nome da imagem (ajuste se for .jpeg)
M = 2 * N + 1;                 % blocos por lado: paredes (ímpares) e células (pares)

% pasta onde todas as imagens geradas serão salvas
pasta = "output";
if ~exist(pasta, "dir")
  mkdir(pasta);
endif

% =====================================================================
% PARTE 1 - Leitura e processamento da imagem
% =====================================================================
disp("=== PARTE 1: imagem ===");

% (a) imagem original
img = imread(arquivo);
figure; imshow(img); title("Imagem original do labirinto");

if ndims(img) == 3
  if size(img, 3) == 4
    img = img(:, :, 1:3);                  % descarta canal alfa
  endif
  img = rgb2gray(img);
endif

% (b) imagem binária: 1 = região livre (branco), 0 = parede (preto)
Bfull = im2double(img) > 0.5;

% recorta as margens brancas ao redor do labirinto
[linhas, colunas] = find(Bfull == 0);
l1 = min(linhas);  l2 = max(linhas);
c1 = min(colunas); c2 = max(colunas);
Bfull   = Bfull(l1:l2, c1:c2);
imgCrop = img(l1:l2, c1:c2);
[alt, larg] = size(Bfull);

% reduz para M x M amostrando o centro de cada bloco
r = min(alt,  floor(((1:M) - 0.5) * alt  / M) + 1);
c = min(larg, floor(((1:M) - 0.5) * larg / M) + 1);
B = Bfull(r, c);

figure; imshow(B); title(sprintf("Imagem binária (%d x %d)", M, M));
imwrite(imgCrop, fullfile(pasta, "labirinto_original.png"));
imwrite(B, fullfile(pasta, "labirinto_binario.png"));

% (c) B(i,j) = 1: pixel de região livre (corredor); B(i,j) = 0: parede.

% (d) entrada e saída: aberturas (pixels livres) na borda externa, sem os cantos
ab = zeros(0, 2);
for k = 2:M-1
  if B(k, 1), ab(end+1, :) = [k 1]; endif   % borda esquerda
  if B(k, M), ab(end+1, :) = [k M]; endif   % borda direita
  if B(1, k), ab(end+1, :) = [1 k]; endif   % borda superior
  if B(M, k), ab(end+1, :) = [M k]; endif   % borda inferior
endfor
if rows(ab) ~= 2
  disp(ab);
  error("Esperava 2 aberturas na borda (entrada e saída), mas achei %d.", rows(ab));
endif

% convenção: a abertura mais à esquerda é a entrada; a outra é a saída
ab = sortrows(ab, [2 1]);

% converte pixel da borda -> célula (i,j)
cel = zeros(2, 2);
for k = 1:2
  for q = 1:2
    p = ab(k, q);
    if p == 1
      cel(k, q) = 1;
    elseif p == M
      cel(k, q) = N;
    elseif mod(p, 2) == 0
      cel(k, q) = p / 2;
    else
      error("Abertura em posição ímpar (%d): não alinhada com uma célula.", p);
    endif
  endfor
endfor
entrada = cel(1, :);
saida   = cel(2, :);
printf("Entrada: pixel (%d,%d) -> célula (%d,%d)\n", ab(1,1), ab(1,2), entrada(1), entrada(2));
printf("Saída:   pixel (%d,%d) -> célula (%d,%d)\n", ab(2,1), ab(2,2), saida(1), saida(2));

% =====================================================================
% PARTE 2 - Da imagem ao grafo
% =====================================================================
disp("=== PARTE 2: grafo ===");
nV = N * N;

% (a) identificador de cada célula: id(i,j) = (i-1)N + j
[J, I] = meshgrid(1:N, 1:N);
IDs = id_no(I, J, N);

% (b) centro de cada célula na imagem
[x, y] = coordenada_no((1:nV)', N, alt, larg);
xy = [x y];

% A célula (i,j) corresponde ao pixel (2i,2j) de B. O pixel entre duas
% células vizinhas é parede (0) ou passagem (1).
centros = B(2:2:2*N, 2:2:2*N);
if ~all(centros(:))
  warning("Há %d células com o centro em parede; confira a binarização.", sum(~centros(:)));
endif

% (c) passagens horizontais e (d) verticais -> (e) conjunto de arestas
E = zeros(0, 2);
for i = 1:N
  for j = 1:N
    if j < N && B(2*i, 2*j + 1)            % entre (i,j) e (i,j+1)
      E(end+1, :) = [IDs(i, j), IDs(i, j+1)];
    endif
    if i < N && B(2*i + 1, 2*j)            % entre (i,j) e (i+1,j)
      E(end+1, :) = [IDs(i, j), IDs(i+1, j)];
    endif
  endfor
endfor

% matriz de adjacência (simétrica: cada aresta vale nos dois sentidos, custo 1)
A = sparse([E(:,1); E(:,2)], [E(:,2); E(:,1)], 1, nV, nV);

s = id_no(entrada(1), entrada(2), N);
t = id_no(saida(1),   saida(2),   N);

% (f) contagens
printf("Número de vértices: %d\n", nV);
printf("Número de arestas:  %d\n", rows(E));
printf("Vértice inicial s = %d, vértice final t = %d\n", s, t);

% =====================================================================
% PARTE 3 - Visualização do grafo (verificação)
% =====================================================================
disp("=== PARTE 3: verificação do grafo ===");

% (d) nenhuma aresta pode atravessar parede: todos os pixels de B entre
% as duas células de cada aresta devem ser livres.
Ei = floor((E - 1) / N) + 1;
Ej = mod(E - 1, N) + 1;
cruzam = 0;
for k = 1:rows(E)
  lin = 2 * min(Ei(k, :)) : 2 * max(Ei(k, :));
  col = 2 * min(Ej(k, :)) : 2 * max(Ej(k, :));
  if ~all(all(B(lin, col)))
    cruzam = cruzam + 1;
  endif
endfor
printf("Arestas que atravessam parede: %d\n", cruzam);

% =====================================================================
% PARTE 4 - Formulação como problema de caminho mínimo
% =====================================================================
disp("=== PARTE 4: formulação ===");

% (a) s e t
printf("(a) s = %d (célula (%d,%d)),  t = %d (célula (%d,%d))\n", ...
       s, entrada(1), entrada(2), t, saida(1), saida(2));
if ~all(nonzeros(A) == 1)
  warning("Há arestas com custo diferente de 1.");
endif
if nnz(A - A') ~= 0
  warning("A matriz de adjacência não é simétrica.");
endif

% (b) e (c) estão explicados no relatório:
%  (b) cada célula é um vértice e cada passagem livre é uma aresta; ir da
%      entrada à saída é percorrer um caminho P = (s, v1, ..., vk, t) em G, e
%      queremos o de menor custo total C(P): um problema de caminho mínimo.
%  (c) como c_e = 1, C(P) = |P| - 1 é o número de movimentos entre células.

% =====================================================================
% PARTE 5 - Algoritmo de Dijkstra
% =====================================================================
disp("=== PARTE 5: Dijkstra ===");
tic;
[dist, anterior] = dijkstra(A, s);
tempo = toc;

% =====================================================================
% PARTE 6 - Reconstrução do caminho mínimo
% =====================================================================
disp("=== PARTE 6: caminho mínimo ===");
caminho = reconstruir_caminho(anterior, s, t);
if isempty(caminho)
  error("Não existe caminho de s até t.");
endif

custo       = dist(t);                  % (a) custo do caminho mínimo
movimentos  = numel(caminho) - 1;       % (b) número de movimentos
n_caminho   = numel(caminho);           % (c) vértices no caminho
if custo ~= movimentos
  warning("Custo (%d) diferente do número de movimentos (%d).", custo, movimentos);
endif

% (d) tempo: uma execução e média de várias execuções
reps = 50;
tic;
for k = 1:reps
  dijkstra(A, s);
endfor
tempo_medio = toc / reps;

printf("(a) Custo do caminho mínimo:    %d\n", custo);
printf("(b) Número de movimentos:       %d\n", movimentos);
printf("(c) Vértices no caminho:        %d\n", n_caminho);
printf("(d) Tempo do Dijkstra:          %.4f s (1 execução); %.4f s (média de %d)\n", ...
       tempo, tempo_medio, reps);

% =====================================================================
% PARTE 7 - Figuras
% =====================================================================
disp("=== PARTE 7: figuras ===");

cor_aresta  = [1 0.5 0];       % laranja
cor_vertice = [0.2 0.2 0.2];   % cinza escuro

% (a) labirinto original, com entrada e saída
figure; imshow(imgCrop); hold on;
plot(xy(s,1), xy(s,2), 'o', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
plot(xy(t,1), xy(t,2), 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
title("Labirinto original (verde = entrada, azul = saída)");
hold off;
print("-dpng", "-r150", fullfile(pasta, "labirinto_entrada_saida.png"));

% (b) grafo, (c) caminho mínimo, (d) grafo + caminho
modos   = {"grafo", "caminho", "ambos"};
titulos = {"Grafo sobre o labirinto", ...
           "Caminho mínimo sobre o labirinto", ...
           "Grafo completo com o caminho mínimo destacado"};
arqs    = {"grafo_sobre_labirinto.png", "caminho_minimo.png", "grafo_e_caminho.png"};

Xe = [xy(E(:,1), 1), xy(E(:,2), 1)]';
Ye = [xy(E(:,1), 2), xy(E(:,2), 2)]';

for m = 1:3
  figure; imshow(imgCrop); hold on;

  if any(strcmp(modos{m}, {"grafo", "ambos"}))
    plot(Xe, Ye, '-', 'Color', cor_aresta, 'LineWidth', 1.5);
    plot(xy(:,1), xy(:,2), '.', 'Color', cor_vertice, 'MarkerSize', 8);
  endif

  if any(strcmp(modos{m}, {"caminho", "ambos"}))
    plot(xy(caminho,1), xy(caminho,2), 'r-', 'LineWidth', 3);
  endif

  plot(xy(s,1), xy(s,2), 'o', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
  plot(xy(t,1), xy(t,2), 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k', 'MarkerSize', 10);
  title(titulos{m});
  hold off;
  print("-dpng", "-r150", fullfile(pasta, arqs{m}));
endfor

printf("Figuras salvas na pasta \"%s\":\n", pasta);
disp("  labirinto_original.png, labirinto_binario.png, labirinto_entrada_saida.png,");
disp("  grafo_sobre_labirinto.png, caminho_minimo.png, grafo_e_caminho.png");