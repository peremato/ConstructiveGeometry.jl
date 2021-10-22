module TriangleMeshes
using StaticArrays
using FastClosures
using IGLWrap_jll

# IGL interface ««1

libiglwrap="../iglwrap/local/libiglwrap.so"
# the bits types are hard-coded on the C side:
const Point=SVector{3,Cdouble}
const Face=NTuple{3,Cint}
@inline _face(a)=(Cint.(a[1:3])...,)

struct TriangleMesh{T,A}
	vertices::Vector{SVector{3,T}}
	faces::Vector{Face}
	attributes::Vector{A}
	@inline TriangleMesh{T,A}(v, f, a) where{T,A} =
		new{T,A}(v, _face.(f), a)
	@inline TriangleMesh{T}(v, f, a::AbstractVector{A}) where{T,A} =
		TriangleMesh{T,A}(v, f, a)
end

const CTriangleMesh = TriangleMesh{Cdouble}

@inline vertices(m::TriangleMesh) = m.vertices
@inline faces(m::TriangleMesh) = m.faces
@inline attributes(m::TriangleMesh) = m.attributes
@inline nvertices(m::TriangleMesh) = size(m.vertices, 1)
@inline nfaces(m::TriangleMesh) = size(m.faces, 1)
@inline shift(f::Face, k) = f .+ Face((k,k,k))
@inline vpointer(m::TriangleMesh{Cdouble}) =
	convert(Ptr{Cdouble}, pointer(m.vertices))
@inline fpointer(m::TriangleMesh) = convert(Ptr{Cint}, pointer(m.faces))

function boolean(op, m1::CTriangleMesh{A}, m2::CTriangleMesh{A}) where{A}#««
	n = nfaces(m1)
	nvo = Ref(Cint(0))
	nfo = Ref(Cint(0))
	vo = Ref(Ptr{Cdouble}(0))
	fo = Ref(Ptr{Cint}(0))
	j = Ref(Ptr{Cint}(0));
	r = ccall((:igl_mesh_boolean, libiglwrap), Cint,
		(Cint,
		Cint, Cint, Ref{Cdouble}, Ref{Cint},
		Cint, Cint, Ref{Cdouble}, Ref{Cint},
		Ref{Cint}, Ref{Cint}, Ref{Ptr{Cdouble}}, Ref{Ptr{Cint}}, Ref{Ptr{Cint}}),
		op,
		nvertices(m1), nfaces(m1), vpointer(m1), fpointer(m1),
		nvertices(m2), nfaces(m2), vpointer(m2), fpointer(m2),
		nvo, nfo, vo, fo, j)
	rvo = unsafe_wrap(Array, convert(Ptr{Point},vo[]), Int(nvo[]); own=true)
	rfo = unsafe_wrap(Array, convert(Ptr{Face}, fo[]), Int(nfo[]); own=true)
	index = unsafe_wrap(Array, j[], (Int(nfo[]),); own=true);
	ao = [ i ≤ n ? m1.attributes[i] : m2.attributes[i-n] for i in index ]
	return TriangleMesh{Cdouble,A}(rvo, rfo, ao)
end#»»
function ispwn(m::TriangleMesh)#««
	r = ccall((:igl_mesh_is_pwn, libiglwrap), Cint,
		(Cint, Cint, Ref{Cdouble}, Ref{Cint},),
		nvertices(m), nfaces(m), vpointer(m), fpointer(m),
		)
	return (r ≠ 0)
end#»»
function offset(m::CTriangleMesh{A}, level::Real, grid::Integer) where{A}#««
	nvo = Ref(Cint(0))
	nfo = Ref(Cint(0))
	vo = Ref(Ptr{Cdouble}(0))
	fo = Ref(Ptr{Cint}(0))
	r = @ccall libiglwrap.offset_surface(
		nvertices(m)::Cint, nfaces(m)::Cint,
		vpointer(m)::Ref{Cdouble}, fpointer(m)::Ref{Cint},
		level::Cdouble, grid::Cint,
		nvo::Ref{Cint}, nfo::Ref{Cint}, vo::Ref{Ptr{Cdouble}}, fo::Ref{Ptr{Cint}}
		)::Cint
	@assert r == 0

	rvo = unsafe_wrap(Array, convert(Ptr{Point},vo[]), Int(nvo[]); own=true)
	rfo = unsafe_wrap(Array, convert(Ptr{Face}, fo[]), Int(nfo[]); own=true)
	return TriangleMesh{Cdouble,A}(rvo, rfo,
		fill(first(m.attributes), nfo[]))
end#»»
function decimate(m::CTriangleMesh{A}, max_faces::Integer) where{A}#««
	nvo = Ref(Cint(0))
	nfo = Ref(Cint(0))
	vo = Ref(Ptr{Cdouble}(0))
	fo = Ref(Ptr{Cint}(0))
	j = Ref(Ptr{Cint}(0));
	r = @ccall libiglwrap.decimate(
		nvertices(m)::Cint, nfaces(m)::Cint,
		vpointer(m)::Ref{Cdouble}, fpointer(m)::Ref{Cint},
		max_faces::Cint,
		nvo::Ref{Cint}, nfo::Ref{Cint}, vo::Ref{Ptr{Cdouble}}, fo::Ref{Ptr{Cint}},
		j::Ref{Ptr{Cint}})::Cint
	@assert r == 0

	rvo = unsafe_wrap(Array, convert(Ptr{Point},vo[]), Int(nvo[]); own=true)
	rfo = unsafe_wrap(Array, convert(Ptr{Face}, fo[]), Int(nfo[]); own=true)
	index = unsafe_wrap(Array, j[], (Int(nfo[]),); own=true);
	return TriangleMesh{Cdouble,A}(rvo, rfo, [m.attributes[i] for i in index])
end#»»
mutable struct Vec3d
	x::Float64
	y::Float64
	z::Float64
end
function halfspace(direction, origin, m::CTriangleMesh{A}, color) where{A}
	nvo = Ref(Cint(0))
	nfo = Ref(Cint(0))
	vo = Ref(Ptr{Cdouble}(0))
	fo = Ref(Ptr{Cint}(0))
	j = Ref(Ptr{Cint}(0));
	r = @ccall libiglwrap.intersect_with_half_space(
		nvertices(m)::Cint, nfaces(m)::Cint,
		vpointer(m)::Ref{Cdouble}, fpointer(m)::Ref{Cint},
		Vec3d(origin...)::Ref{Vec3d},
		Vec3d(direction...)::Ref{Vec3d},
		nvo::Ref{Cint}, nfo::Ref{Cint}, vo::Ref{Ptr{Cdouble}}, fo::Ref{Ptr{Cint}},
		j::Ref{Ptr{Cint}})::Cint
	@assert r == 0

	rvo = unsafe_wrap(Array, convert(Ptr{Point},vo[]), Int(nvo[]); own=true)
	rfo = unsafe_wrap(Array, convert(Ptr{Face}, fo[]), Int(nfo[]); own=true)
	index = unsafe_wrap(Array, j[], (Int(nfo[]),); own=true);
	return TriangleMesh{Cdouble,A}(rvo, rfo,
		[(i <= nfaces(m) ? m.attributes[i] : color) for i in index])
end

@inline Base.union(m1::CTriangleMesh, m2::CTriangleMesh) = boolean(0, m1, m2)
@inline Base.intersect(m1::CTriangleMesh, m2::CTriangleMesh)= boolean(1, m1, m2)
@inline Base.setdiff(m1::CTriangleMesh, m2::CTriangleMesh) = boolean(2, m1, m2)
@inline Base.symdiff(m1::CTriangleMesh, m2::CTriangleMesh) = boolean(3, m1, m2)

# Own functions ««1

"""
    plane_slice(m::TriangleMesh)

Returns the set of all edges formed by this mesh ∩ the horizontal plane,
as `(vertices, edges)`, where `vertices` are 2d points,
and `edges` are indices into `vertices`.
"""
function plane_slice(m::TriangleMesh)
	# build a list of intersection points + connectivity
	# each intersection point is either:
	#  - a vertex v, represented as (v, 0)
	#  - in the edge (v1v2), represented as (v1,v2)
	points = Dict{NTuple{2,Int},Int}()
	elist = NTuple{2,Int}[]
	pindex = @closure v->get!(points, extrema(v), length(points)+1)
	edge! = @closure (v,w)-> push!(elist, minmax(pindex(v),pindex(w)))
	# build list of all edges:
	for (i1, i2, i3) in faces(m)
		(v1, v2, v3) = vertices(m)[[i1,i2,i3]]
		if v1[3] == 0#««
			if v2[3] == 0
				v3[3] == 0 && continue # 000: ignore horizontal triangle
				edge!(i1=>0,i2=>0) # 00+, 00-
			elseif v2[3] > 0
				v3[3] == 0 && edge!(i1=>0,i3=>0)
				v3[3] < 0 && edge!(i1=>0,i2=>i3)
			else # v2[3] < 0
				v3[3] == 0 && edge!(i1=>0,i3=>0)
				v3[3] > 0 && edge!(i1=>0,i2=>i3)
			end
		elseif v1[3] > 0
			if v2[3] == 0
				v3[3] == 0 && edge!(i2=>0,i3=>0) # +00
				v3[3] < 0 && edge!(i2=>0,i1=>i3) # +0-
			elseif v2[3] > 0
				v3[3] < 0 && edge!(i1=>i3,i2=>i3) # ++-
			else # v2[3] < 0
				v3[3] == 0 && edge!(i3=>0,i1=>i2)
				v3[3] > 0 && edge!(i1=>i2,i2=>i3)#+-+
				v3[3] < 0 && edge!(i1=>i2,i1=>i3)#+--
			end
		else # v1[3] < 0
			if v2[3] == 0
				v3[3] == 0 && edge!(i2=>0,i3=>0) # -00
				v3[3] > 0 && edge!(i2=>0,i1=>i3) # -0+
			elseif v2[3] > 0
				v3[3] == 0 && edge!(i3=>0,i1=>i2)
				v3[3] > 0 && edge!(i1=>i2,i1=>i3)#-++
				v3[3] < 0 && edge!(i1=>i2,i2=>i3)#-+-
			else # v2[3] < 0
				v3[3] > 0 && edge!(i1=>i3,i2=>i3) # --+
			end
		end#»»
	end
	vlist = Vector{SVector{2,Float64}}(undef, length(points))
	for ((i1,i2),j) in pairs(points)
		if iszero(i1)
			v = vertices(m)[i2]
			vlist[j] = SA[v[1],v[2]]
		else
			(v1,v2) = vertices(m)[[i1,i2]]
			(z1,z2) = (v1[3],v2[3]); f = 1/(z2-z1)
			# (z2 v1 - z1 v2)/(z2-z1)
			vlist[j] = SA[f*(z2*v1[1]-z1*v2[1]), f*(z2*v1[2]-z1*v2[2])]
		end
	end
	return (vlist, unique!(sort!(elist)))
end


#  »»1

export TriangleMesh
end
