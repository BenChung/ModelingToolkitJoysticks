using ModelingToolkit, GLFW, ModelingToolkitJoystick
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrdinaryDiffEqTsit5, Dates
@named joystick = Joystick(GLFW.JOYSTICK_1)
@variables intx(t) = 0.0 inty(t) = 0.0
@named sys = ODESystem([
    D(intx) ~ joystick.axis1
    D(inty) ~ joystick.axis2
], t, systems=[joystick])
ssys =structural_simplify(sys)
prob = ODEProblem(ssys, [], (0.0, 1.0))

integrator = init(prob, Tsit5())
last_time = nothing
dt_next = 1/60.0
target_dt = 1/60.0
dt_err_int = 0.0
for i=1:240*10
    if isnothing(last_time)
        last_time = now()
    else 
        dt_next = 0.9 * dt_next + 0.1*Float64((now() - last_time)/Dates.Second(1.0))
        last_time = now()
    end
    step!(integrator, dt_next, true)
    @show target_dt - dt_next
    dt_err_int += target_dt - dt_next
    sleep(1/100.0 + 0.01*dt_err_int)
end

solve(prob, Tsit5())