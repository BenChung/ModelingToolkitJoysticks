module ModelingToolkitJoystick
using ModelingToolkit, GLFW, Symbolics
using ModelingToolkit: t_nounits as t, D_nounits as D

struct JoystickHandle
    js::GLFW.Joystick
end
Base.nameof(::JoystickHandle) = :JoystickHandle
@register_array_symbolic (h::JoystickHandle)(placeholder) begin 
    size=(length(GLFW.GetJoystickAxes(h.js)),)
    eltype=Float64
end
(h::JoystickHandle)(x) = GLFW.GetJoystickAxes(h.js)

@component function Joystick(joystick::GLFW.Joystick; name)
    naxes = length(GLFW.GetJoystickAxes(joystick))
    @variables y(t) = 0.0
    vars = [(@variables $(Symbol("axis$i"))(t))[1] for i ∈ 1:naxes]
    handle = JoystickHandle(joystick)
    return ODESystem(
        [
            D(y) ~ 0.0, # this is just here to keep the joystick evaluating...
            vars ~ handle(y)
        ], t, [vars; y], []; name=name
    )
end

@component function Joystick(; name, number::Int=1)
    return Joystick(get_joystick_by_number(number); name=name)
end
get_joystick_by_number(num) = if num >= 1 && num <= 16 GLFW.Joystick(num - 1) else throw("Invalid joystick number $num") end

end # module ModelingToolkitJoystick
