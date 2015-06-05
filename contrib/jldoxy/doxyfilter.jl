#!/usr/bin/env julia
using JuliaParser

function parsefile(filename)
    src=IOBuffer()
    write(src, "begin\n")
    write(src, open(readall, filename))
    write(src, "\nend")
    Parser.parse(bytestring(src))
end

ast = parsefile(ARGS[1])

out = Any[]
for node in ast.args
	:head in names(node) || continue
	if node.head == :function
		#Parse function signature
		signature = node.args[1].args
		push!(out, string("Any ", signature[1]), "(")
		decl = Any[]
		for arg in signature[2:end]
			if typeof(arg)==Symbol
				push!(decl, string("Any ", arg))
			elseif typeof(arg)==Expr && arg.head == :(::)
				if length(arg.args)==1 #::Type{T}
					push!(decl, string(arg.args[1]))
				else #src::Array
					push!(decl, string(arg.args[2], " ", arg.args[1]))
				end
			elseif typeof(arg)==Expr && arg.head == :kw #1 kwarg
				warn("Skipping kwargs: $arg")
			elseif typeof(arg)==Expr && arg.head == :(...) #varargs
				info("Discarding info about varargs: $arg")
				push!(decl, "...")
			else
				warn(string("Cannot parse: ", arg, " in ", signature[1]))
			end
		end
		push!(out, join(decl, ", "))
		push!(out, ") {\n")
		push!(out, node.args[2])
		push!(out, "\n}\n")
	end
end

println(join(out))
