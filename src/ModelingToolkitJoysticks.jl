module ModelingToolkitJoysticks
using ModelingToolkit, GLFW, Symbolics, Setfield, Dates
using ModelingToolkit: t_nounits as t, D_nounits as D

@component function Joystick(joystick::GLFW.Joystick; name, update_rate=1/60)
    naxes = length(GLFW.GetJoystickAxes(joystick))
    names = [Symbol("axis$i") for i ∈ 1:naxes]
    pars = [(@parameters $(n)(t)=0.0)[1] for n ∈ names]
    return ODESystem(
        Equation[], t, [], pars; name=name,
        discrete_events = [update_rate => ModelingToolkit.ImperativeAffect(modified = NamedTuple{(names...,)}(pars)) do m, _, _, _
            return NamedTuple{keys(m)}(GLFW.GetJoystickAxes(joystick))
        end]
    )
end

@component function Joystick(; name, number::Int=1)
    return Joystick(get_joystick_by_number(number); name=name)
end
get_joystick_by_number(num) = if num >= 1 && num <= 16 GLFW.Joystick(num - 1) else throw("Invalid joystick number $num") end


@component function FrameLimiter(;name, 
    frametime_target=1/60, sleep_guess=frametime_target, onupdate=nothing,
    observed=(;))
    @parameters dt_act(t)=0.0 last_time(t)=NaN
    epoch = now()
    # todo: fix empty return
    enforce_frametime = ModelingToolkit.ImperativeAffect(; modified = (;dt_act, last_time), observed) do m,o,_,integ
        dt_act, last_time = m
        if isnan(last_time)
            last_time = (now() - epoch)/Second(1)
            return (;dt_act, last_time)
        end
        current_time = (now() - epoch)/Second(1)
        dt = current_time - last_time
        dt_err = frametime_target - dt
        last_time = current_time
        if !isnothing(onupdate)
            onupdate(o, integ)
        end
        dt_act += dt_err * 0.05
        @show integ.t
        sleep(max(sleep_guess + dt_act, 0.0))
        return (;dt_act, last_time)
    end
    return ODESystem(
        Equation[], t, [], [dt_act, last_time]; name=name, 
        discrete_events = [frametime_target => enforce_frametime]
    )
end

export Joystick
end # module ModelingToolkitJoystick
