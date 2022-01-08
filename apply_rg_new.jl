### A Pluto.jl notebook ###
# v0.16.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 227e8e30-1665-11ec-11ee-215d99ce71b5
begin
	let
			using Pkg
		Pkg.activate(mktempdir())
		Pkg.Registry.update()
		Pkg.add([
				"PlutoUI"
				"BenchmarkTools"
				"CairoMakie"
				"DICOM"
				"Images"
				"ImageMorphology"
				"ImageSegmentation"
				"DataFrames"
				"CSV"
				"StatsBase"
				"Statistics"
				
				])
		Pkg.add([
				Pkg.PackageSpec(url="https://github.com/JuliaNeuroscience/NIfTI.jl")
				Pkg.PackageSpec(url="https://github.com/Dale-Black/IntegratedHU.jl")
				Pkg.PackageSpec(url="https://github.com/Dale-Black/DICOMUtils.jl")
				Pkg.PackageSpec(url="https://github.com/Dale-Black/CalciumScoring.jl")
				])
	end

	using PlutoUI
	using Statistics
	using BenchmarkTools
	using CairoMakie
	using DICOM
	using NIfTI
	using Images
	using ImageMorphology
	using ImageSegmentation
	using DataFrames
	using IntegratedHU
	using DICOMUtils
	using CSV
	using StatsBase
	using CalciumScoring
	using Statistics
	
end

# ╔═╡ 16359e47-91cf-417c-b900-27fdf9e3808b
TableOfContents()

# ╔═╡ 07b91fb8-66d6-4e2f-bd86-762f2bbda953
md"""
## Load data
"""

# ╔═╡ 89f269d5-898c-4a99-b0cd-0f3ace29d35f
begin
	image_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\rescan\10_01_21\Vol0_50mgcc\120"
end

# ╔═╡ 2189f73d-d830-4914-95cd-24c4f184f6cc
begin
	label_path = raw"Y:\Canon Images for Dynamic Heart Phantom\Dynamic Phantom\clean_data\rescan\10_01_21\VOL_SEG\120\1.nii"
end

# ╔═╡ cf0dc8ed-2112-4d3e-95b8-4b9d3b40cc3b
begin
	lbl = niread(label_path)
	lbl_array = copy(lbl.raw)
end;

# ╔═╡ dc60f456-9e52-44e9-9732-aedf26e9e44d
img = dcmdir_parse(image_path);

# ╔═╡ 21bf5ab6-c49c-40a8-8c93-54425eee8aa0
orient = (("R", "A", "I"))  # Different from previous scans (RPI)

# ╔═╡ 2f8e4304-275a-4a71-afaa-34cd94ac15e5
begin
	# Reorient
	img_array = load_dcm_array(img)
	img_array, affvol, new_affvol = DICOMUtils.orientation(img_array, orient)
	img_array = permutedims(img_array, (2, 1, 3))
end;

# ╔═╡ 36788f4a-887d-4524-b43d-e11f6593e897
md"""
## Visualize
"""

# ╔═╡ 9fcaf822-b5a8-41c9-be45-30ca985b3f23
function collect_tuple(tuple_array)
	row_num = size(tuple_array)
	col_num = length(tuple_array[1])
	container = zeros(Int64, row_num..., col_num)
	for i in 1:length(tuple_array)
		container[i,:] = collect(tuple_array[i])
	end
	return container
end

# ╔═╡ a73a3969-a1ba-4ec9-b217-a5ce879ce9b1
l_indices = findall(x -> x == 1.0, lbl_array);

# ╔═╡ 549331ef-fca0-48f1-9a64-c5802e64695b
li = Tuple.(l_indices);

# ╔═╡ f22a6e94-a744-4e62-99b5-da3708973e7e
label_arr = collect_tuple(li);

# ╔═╡ 069c842b-8149-439c-8e17-d498c6fc34c9
zs_l = unique(label_arr[:,3])

# ╔═╡ 6f634f8e-2fc9-4cd4-b8f1-b817cb6a2ca2
@bind q PlutoUI.Slider(1:length(zs_l), default=10, show_value=true)

# ╔═╡ 74aeb4b9-c291-493a-867c-51270caeb928
indices_l = findall(x -> x == zs_l[q], label_arr[:,3]);

# ╔═╡ 27b39566-b036-42c9-a815-8d340af560da
begin
	fig = Figure()
	
	ax = Makie.Axis(fig[1, 1])
	ax.title = "Large Insert (135 kV)"
	heatmap!(ax, img_array[:,:,zs_l[q]], colormap=:grays)
	scatter!(ax, label_arr[:,1][indices_l], label_arr[:,2][indices_l], markersize=1, color=:red)
	fig
end

# ╔═╡ fefd1a6f-bb81-4a94-9494-9b8d3fb5cf0a
@bind l PlutoUI.Slider(1:length(zs_l), default=10, show_value=true)

# ╔═╡ c1267996-bd19-4e24-83cd-2858ebe9fa3a
begin
	fig2 = Figure()
	
	ax2 = Makie.Axis(fig2[1, 1])
	ax2.title = "Region of Interest"
	heatmap!(ax2, img_array[170:310,170:310,zs_l[l]], colormap=:grays)

	fig2
end

# ╔═╡ 168da87b-c873-45ab-9c57-ca37702e8946
@bind h PlutoUI.Slider(1:length(zs_l), default=10, show_value=true)

# ╔═╡ 50f765f8-fb82-4ee0-a25d-2428c67a4ca0
begin
	o = copy(lbl_array[255:265,270:280,zs_l[h]]) 
	o = replace!(o,0=>-1024)
	
	idxs = findall(x -> x == 1, o)
	o[idxs] .= copy(img_array[255:265,270:280,zs_l[h]][idxs]) 
	
	o
end

# ╔═╡ 9b54238b-834d-448a-8da8-eb4cfe59437c
img_array[255:265,270:280,zs_l[h]]

# ╔═╡ 2d567d5d-f517-4ab5-839e-e9ccd45a5894
begin
	fig9 = Figure()
	
	ax9 = Makie.Axis(fig9[1, 1])
	heatmap!(ax9, img_array[255:265,270:280,154], colormap=:grays)

	fig9
end

# ╔═╡ 951844f6-64be-46e6-9950-01344f214bbf
md"""
## Algorithm
"""

# ╔═╡ ce8e20c6-70b7-4b6a-b258-c1a4bab182c3
md"""
### Core `S_Obj`
"""

# ╔═╡ d295fe05-6644-43fd-9f48-df6e66cec159
begin
	c = copy(lbl_array[170:310,170:310,zs_l]) # c is segmented volume (boolean array)
	c = replace!(c,0=>-1024)  # change the unsegmented volume to -1024 (air)
	
	idxs1 = findall(x -> x == 1, c)
	c[idxs1] .= copy(img_array[170:310,170:310,zs_l][idxs1]) # fill in HU values
	
	HU = unique(c) # find all possible HU values
	filter!(x->x≠-1024,HU) # exclude -1024 in HU collection
end

# ╔═╡ 4ac4b504-dc6c-44de-8623-b9e7db7f39cf
begin
	seed_obj =  Int.(round(quantile!(HU,0.99))) # pure calcium
	seed_bkg =  Int.(round(quantile!(HU,0.55))) # calcium affected by partial volume effect
	seed_air = 	minimum(HU)
	
	index_obj = findall(x -> x >= seed_obj, c)
	index_bkg = findall(x -> abs(x - seed_bkg)<=3, c)
	index_nan = findall(x -> x == seed_air, c)
end;

# ╔═╡ a5666804-0e9f-48a8-aec6-0883f1df93dc
seeds = [(index_obj[1],3),(index_obj[end],3),
		 (index_bkg[1],2),(index_bkg[end],2),
		 (index_nan[1],1),(index_nan[end],1)]

# ╔═╡ 7e7bcf90-2149-46a2-a90e-b6facc7e1ef4
region_grow = seeded_region_growing(c, seeds)

# ╔═╡ 77c33af3-9a5b-4cc7-8ed1-62a2472c13e6
@bind p PlutoUI.Slider(1:length(zs_l), default=10, show_value=true)

# ╔═╡ 7a0e6791-0167-4c9b-8a56-db02340fbdaf
begin
	fig3 = Figure()
	
	ax3 = Makie.Axis(fig3[1, 1])
	ax3.title = "Region Growing"
	heatmap!(ax3, labels_map(region_grow)[:,:,p], colormap=:grays)

	fig3
end

# ╔═╡ c54216ed-c928-44d6-9165-e7b51ba7bbaa
begin
	obj = map(i->i==3,labels_map(region_grow))	
	S_Obj = mean(c[obj])
end

# ╔═╡ dbefed2f-2027-4301-92c1-412e508cd005
md"""
### Ring `S_Bkg`
"""

# ╔═╡ e827aa50-1846-4355-bbf9-4492c58296d5
begin
	r = copy(dilate(dilate(dilate(lbl_array[170:310,170:310,zs_l])))-dilate(dilate(lbl_array[170:310,170:310,zs_l]))) # r is ring (boolean array)
	r = replace!(r,0=>-1024) 
	
	idxs2 = findall(x -> x == 1, r)
	r[idxs2] .= copy(img_array[170:310,170:310,zs_l][idxs2])
	
	S_Bkg = mean(r[r.> -1024])
end

# ╔═╡ 03cff6ef-c1af-4c0d-b0bd-f77801f3fc8a
# this cell is for uniormly eroded core

#begin
#	co = copy(erode(lbl_array[170:310,170:310,zs_l])) 
#	co = replace!(co,0=>-1024) 
	
#	idxs3 = findall(x -> x == 1, co)
#	co[idxs3] .= copy(img_array[170:310,170:310,zs_l][idxs3])
	
#	S_Obj2 = mean(co[co.> -1024])
#end

# ╔═╡ 10842c63-da26-460d-b7b3-42af664864c5
vol = c[c.> -1024]

# ╔═╡ bbe7c786-4864-4ab9-a01b-29f7e1b40c53
alg = Integrated(vol);

# ╔═╡ f9452177-905f-4537-a48c-142647cc4d43
md"""
### `N_Obj`
"""

# ╔═╡ f5cfc086-69d1-42f4-8061-dbf28d43e2ba
N_Obj = CalciumScoring.score(S_Bkg, S_Obj, alg)

# ╔═╡ e1b06c4b-129b-45d8-a160-4cea27d36f1a
md"""
### `V_Obj`
"""

# ╔═╡ 447d5232-77e7-4320-88ba-99aa06b7f4d4
vsize = voxel_size(lbl.header)

# ╔═╡ 87002f66-adf5-4f27-8248-94e71b0ce080
V_Obj = CalciumScoring.score(S_Bkg, S_Obj, vsize, alg)  # mm^3

# ╔═╡ 28e8872f-5341-4375-9f4c-e35fefaca50d
md"""
### `M_Obj`
"""

# ╔═╡ f9b94272-82b7-4e04-b40b-c77cb0cde91e
begin
	ρ_cm = 400 # g/cm^3
	ρ_mm = ρ_cm / 1000 # g/mm^3
end

# ╔═╡ 2a7bb373-29f9-4c2f-87c8-d2505e3df9c3
M_Obj = CalciumScoring.score(S_Bkg, S_Obj, vsize, ρ_mm, alg)

# ╔═╡ adce037a-dff1-4a2c-b309-d2755b845ee4
md"""
### Ground truth
"""

# ╔═╡ 3995f25a-b05f-4869-aa07-376ba83ebcff
mass = (π * (2.5)^2) * 7 * ρ_mm # (area) * (length) * (density)

# ╔═╡ b2ff7b88-c470-414b-b579-7d5619cb226d
(π * (0.6)^2) * 7

# ╔═╡ Cell order:
# ╠═227e8e30-1665-11ec-11ee-215d99ce71b5
# ╠═16359e47-91cf-417c-b900-27fdf9e3808b
# ╟─07b91fb8-66d6-4e2f-bd86-762f2bbda953
# ╠═89f269d5-898c-4a99-b0cd-0f3ace29d35f
# ╠═2189f73d-d830-4914-95cd-24c4f184f6cc
# ╠═cf0dc8ed-2112-4d3e-95b8-4b9d3b40cc3b
# ╠═dc60f456-9e52-44e9-9732-aedf26e9e44d
# ╠═21bf5ab6-c49c-40a8-8c93-54425eee8aa0
# ╠═2f8e4304-275a-4a71-afaa-34cd94ac15e5
# ╟─36788f4a-887d-4524-b43d-e11f6593e897
# ╠═9fcaf822-b5a8-41c9-be45-30ca985b3f23
# ╠═a73a3969-a1ba-4ec9-b217-a5ce879ce9b1
# ╠═549331ef-fca0-48f1-9a64-c5802e64695b
# ╠═f22a6e94-a744-4e62-99b5-da3708973e7e
# ╠═069c842b-8149-439c-8e17-d498c6fc34c9
# ╟─6f634f8e-2fc9-4cd4-b8f1-b817cb6a2ca2
# ╠═74aeb4b9-c291-493a-867c-51270caeb928
# ╟─27b39566-b036-42c9-a815-8d340af560da
# ╟─fefd1a6f-bb81-4a94-9494-9b8d3fb5cf0a
# ╠═c1267996-bd19-4e24-83cd-2858ebe9fa3a
# ╟─168da87b-c873-45ab-9c57-ca37702e8946
# ╠═50f765f8-fb82-4ee0-a25d-2428c67a4ca0
# ╠═9b54238b-834d-448a-8da8-eb4cfe59437c
# ╟─2d567d5d-f517-4ab5-839e-e9ccd45a5894
# ╟─951844f6-64be-46e6-9950-01344f214bbf
# ╟─ce8e20c6-70b7-4b6a-b258-c1a4bab182c3
# ╠═d295fe05-6644-43fd-9f48-df6e66cec159
# ╠═4ac4b504-dc6c-44de-8623-b9e7db7f39cf
# ╠═a5666804-0e9f-48a8-aec6-0883f1df93dc
# ╠═7e7bcf90-2149-46a2-a90e-b6facc7e1ef4
# ╟─77c33af3-9a5b-4cc7-8ed1-62a2472c13e6
# ╟─7a0e6791-0167-4c9b-8a56-db02340fbdaf
# ╠═c54216ed-c928-44d6-9165-e7b51ba7bbaa
# ╟─dbefed2f-2027-4301-92c1-412e508cd005
# ╠═e827aa50-1846-4355-bbf9-4492c58296d5
# ╠═03cff6ef-c1af-4c0d-b0bd-f77801f3fc8a
# ╠═10842c63-da26-460d-b7b3-42af664864c5
# ╠═bbe7c786-4864-4ab9-a01b-29f7e1b40c53
# ╟─f9452177-905f-4537-a48c-142647cc4d43
# ╠═f5cfc086-69d1-42f4-8061-dbf28d43e2ba
# ╟─e1b06c4b-129b-45d8-a160-4cea27d36f1a
# ╠═447d5232-77e7-4320-88ba-99aa06b7f4d4
# ╠═87002f66-adf5-4f27-8248-94e71b0ce080
# ╟─28e8872f-5341-4375-9f4c-e35fefaca50d
# ╠═f9b94272-82b7-4e04-b40b-c77cb0cde91e
# ╠═2a7bb373-29f9-4c2f-87c8-d2505e3df9c3
# ╟─adce037a-dff1-4a2c-b309-d2755b845ee4
# ╠═3995f25a-b05f-4869-aa07-376ba83ebcff
# ╠═b2ff7b88-c470-414b-b579-7d5619cb226d
