using Test
using StaticArrays
include("../src/HalfEdgeMeshes.jl")
HE=HalfEdgeMeshes

nvf(mesh) = (HE.nvertices(mesh), HE.nfaces(mesh))


@testset "Tetrahedra" begin#««
tet(a=1,b=SA[0,0,0])= HE.HalfEdgeMesh(
	a.*[SA[-1.,0,0],SA[1,0,0],SA[0,1,0],SA[0,0,1]] .+ [b,b,b,b],
	[(3,2,1),(1,2,4),(3,1,4),(2,3,4)])
t1=tet(1)
t2=tet(2)
t3=tet(1,[3,0,0])
@test nvf(HE.combine([t2, t1], 1)) == (8, 12)
@test nvf(HE.combine([t1, t2], 1)) == (8, 12)
@test nvf(HE.combine([t1, t2], 2)) == (4, 4)
@test nvf(HE.combine([t2, t1], 2)) == (4, 4)
@test nvf(HE.combine([t1, t3], 1)) == (8, 8)
@test nvf(HE.combine([t3, t1], 1)) == (8, 8)
@test nvf(HE.combine([t1, t3], 2)) == (0, 0)
@test nvf(HE.combine([t3, t1], 2)) == (0, 0)

end#»»
@testset "Cubes" begin#««
cube(a,b,c)=HE.HalfEdgeMesh{Int64,Int64,SArray{Tuple{3},Float64,1,3}}([4, 29, 24, 1, 12, 17, 10, 23, 36, 7, 18, 5, 16, 35, 30, 13, 6, 11, 22, 27, 32, 19, 8, 3, 28, 33, 20, 25, 2, 15, 34, 21, 26, 31, 14, 9], [6, 5, 7, 7, 8, 6, 7, 3, 4, 4, 8, 7, 4, 2, 6, 6, 8, 4, 5, 1, 3, 3, 7, 5, 2, 1, 5, 5, 6, 2, 3, 1, 2, 2, 4, 3], [33, 35, 34, 36, 29, 30, 24, 18], SArray{Tuple{3},Float64,1,3}[[0.0, 0.0, 0.0], [0.0, 0.0, c], [0.0, b, 0.0], [0.0, b, c], [a, 0.0, 0.0], [a, 0.0, c], [a, b, 0.0], [a, b, c]], Tuple{Int8,SArray{Tuple{3},Float64,1,3}}[(1, [0.0, 0.0, a]), (1, [0.0, -0.0, a]), (2, [0.0, 0.0, b]), (2, [-0.0, 0.0, b]), (3, [0.0, 0.0, c]), (3, [0.0, -0.0, c]), (-3, [-0.0, -0.0, 0.0]), (-3, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (-1, [-0.0, -0.0, 0.0]), (-1, [-0.0, -0.0, 0.0])])
c1=cube(2.,1,1)
c2=cube(1.,2,1)
@test HE.volume(HE.combine([c1,c2],1,1e-3))≈3.
@test HE.volume(HE.combine([c1,c2],2,1e-3))≈1.
@test HE.volume(HE.combine([c1,HE.reverse(c2)],2,1e-3))≈1.
@test nvf(HE.combine([c1,c2],1,1e-3)) == (25,46)
@test nvf(HE.combine([c1,c2],2,1e-3)) == (17,30)
@test nvf(HE.combine([c1,HE.reverse(c2)],2,1e-3)) == (12,20)

end#»»

# # h=HalfEdgeMesh(collect(1:4),[[1,2,3],[4,3,2],[4,2,1],[4,1,3]])
# # println("\e[1mrefine:\e[m")
# # h2=refine(h, 5, 1 => [(1,2,5),(2,3,5),(3,1,5)])
# # h3=refine(h, 5, 1 => [(1,2,5),(5,3,1)], 2=>[(4,3,5),(5,2,4)])
# td = HE.concatenate(tet(2), HE.reverse(tet(1)))
# tu = HE.concatenate(tet(1), tet(1, SA[3,0,0]))
# ti = HE.concatenate(tet(1), tet(3))

# stu=Main.HalfEdgeMeshes.HalfEdgeMesh{Int64,Int64,SArray{Tuple{3},Float64,1,3}}([4, 28, 13, 1, 47, 9, 12, 29, 6, 41, 32, 7, 20, 35, 17, 48, 27, 22, 24, 25, 16, 38, 14, 19, 3, 23, 37, 2, 8, 36, 34, 11, 45, 31, 26, 30, 15, 44, 21, 43, 10, 46, 40, 18, 33, 42, 5, 39], [1, 7, 5, 5, 4, 1, 3, 1, 4, 2, 3, 4, 7, 6, 5, 5, 6, 8, 7, 5, 8, 6, 7, 8, 7, 6, 5, 1, 3, 7, 3, 2, 6, 6, 7, 3, 6, 8, 5, 2, 4, 8, 8, 6, 2, 4, 5, 8], [4, 43, 34, 47, 21, 23, 24, 22], SArray{Tuple{3},Float64,1,3}[[-3.0, 0.0, 0.0], [3.0, 0.0, 0.0], [0.0, 3.0, 0.0], [0.0, 0.0, 3.0], [-1.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]], Tuple{Int8,SArray{Tuple{3},Float64,1,3}}[(-3, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (3, [-1.0, 1.0, 3.0]), (3, [1.0, 1.0, 3.0]), (-3, [-0.0, 0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (3, [-1.0, 1.0, 1.0]), (3, [1.0, 1.0, 1.0]), (-3, [-0.0, 0.0, 0.0]), (-3, [-0.0, -0.0, 0.0]), (-3, [-0.0, -0.0, 0.0]), (-3, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (-2, [-0.0, 0.0, 0.0])])
# std=HE.HalfEdgeMesh{Int64,Int64,SArray{Tuple{3},Float64,1,3}}([4, 28, 19, 1, 47, 9, 12, 29, 6, 41, 32, 7, 22, 25, 27, 15, 21, 38, 14, 24, 48, 35, 18, 20, 3, 13, 37, 2, 8, 36, 34, 11, 45, 31, 26, 30, 16, 44, 17, 43, 10, 46, 40, 23, 33, 42, 5, 39], [1, 7, 5, 5, 4, 1, 3, 1, 4, 2, 3, 4, 7, 5, 6, 5, 8, 6, 7, 8, 5, 6, 8, 7, 7, 6, 5, 1, 3, 7, 3, 2, 6, 6, 7, 3, 6, 8, 5, 2, 4, 8, 8, 6, 2, 4, 5, 8], [4, 43, 34, 47, 19, 23, 22, 24], SArray{Tuple{3},Float64,1,3}[[-2.0, 0.0, 0.0], [2.0, 0.0, 0.0], [0.0, 2.0, 0.0], [0.0, 0.0, 2.0], [-1.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]], Tuple{Int8,SArray{Tuple{3},Float64,1,3}}[(-3, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (3, [-1.0, 1.0, 2.0]), (3, [1.0, 1.0, 2.0]), (3, [-0.0, 0.0, 0.0]), (2, [-0.0, -0.0, 0.0]), (-3, [-1.0, 1.0, 1.0]), (-3, [1.0, 1.0, 1.0]), (-3, [-0.0, 0.0, 0.0]), (-3, [-0.0, -0.0, 0.0]), (-3, [-0.0, -0.0, 0.0]), (-3, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (-2, [-0.0, -0.0, 0.0]), (-2, [-0.0, 0.0, 0.0])])


