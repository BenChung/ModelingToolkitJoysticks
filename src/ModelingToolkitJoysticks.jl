module ModelingToolkitJoysticks
using ModelingToolkit, GLFW, Symbolics, Setfield
using ModelingToolkit: t_nounits as t, D_nounits as D

@component function Joystick(joystick::GLFW.Joystick; name, update_rate=1/60)
    naxes = length(GLFW.GetJoystickAxes(joystick))
    pars = [(parameters $(Symbol("axis$i"))(t))[1] for i ∈ 1:naxes]
    return ODESystem(
        [], t, [], pars; name=name,
        discrete_events = [update_rate => ModelingToolkit.ImperativeAffect(modified = pars) do m, _, _, _
            return NamedTuple{keys(m)}(GLFW.GetJoystickAxes(joystick))
        end]
    )
end

@component function Joystick(; name, number::Int=1)
    return Joystick(get_joystick_by_number(number); name=name)
end
get_joystick_by_number(num) = if num >= 1 && num <= 16 GLFW.Joystick(num - 1) else throw("Invalid joystick number $num") end


@component function FrameLimiter(;name, frametime_target=1/60, sleep_guess=frametime_target, onupdate=nothing)
    last_time = nothing
    function limiter(integ, u, p, ctx)
        if isnothing(last_time)
            last_time = now()
            return
        end
        current_time = now()
        dt = current_time - last_time
        dt_err = frametime_target - dt
        last_time = current_time
        if !isnothing(onupdate)
            onupdate(integ)
        end
        sleep(sleep_guess - dt_err)
    end
    return ODESystem(
        [], t; name=name, 
        discrete_events = [frametime_target => (limiter, [], [], [], nothing)]
    )
end

export Joystick
end # module ModelingToolkitJoystick
