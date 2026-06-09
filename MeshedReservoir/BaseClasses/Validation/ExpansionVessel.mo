within MeshedReservoir.BaseClasses.Validation;
model ExpansionVessel "Validation model for ExpansionVessel"
  extends Modelica.Icons.Example;

  package MediumWat = Buildings.Media.Specialized.Water.TemperatureDependentDensity
    "Medium model for water";
  package MediumAir = Modelica.Media.Air.SimpleAir
    "Medium model for air";

  MeshedReservoir.BaseClasses.ExpansionVessel exp(
    redeclare package Medium = MediumWat,
    redeclare package MediumAir= MediumAir,
    VTot=1,
    p_start=300000) "Expansion vessel"
    annotation (Placement(transformation(extent={{20,-10},{40,10}})));

  Buildings.Fluid.Sources.MassFlowSource_T sou(
    redeclare package Medium = MediumWat,
    use_m_flow_in=true,
    m_flow=0.1,
    T=293.15,
    nPorts=1) "Mass flow source"
    annotation (Placement(transformation(extent={{-40,-30},{-20,-10}})));

  Buildings.Controls.OBC.CDL.Reals.Sources.TimeTable timTab(
    table=[
      0,0;
      3600,0;
      3600,0.05;
      7200,0.05;
      7200,0],
    smoothness=Buildings.Controls.OBC.CDL.Types.Smoothness.ConstantSegments,
    extrapolation=Buildings.Controls.OBC.CDL.Types.Extrapolation.HoldLastPoint)
    "Time schedule: 0 for t=0...60s, 1 for t=60...120s, then 0"
    annotation (Placement(transformation(extent={{-80,-22},{-60,-2}})));

equation
  connect(timTab.y[1], sou.m_flow_in)
    annotation (Line(points={{-58,-12},{-42,-12}},     color={0,0,127}));
  connect(sou.ports[1], exp.portWat)
    annotation (Line(points={{-20,-20},{30,-20},{30,-10}},
                                                       color={0,127,255}));

  annotation (
    Documentation(info="<html>
<p>
This model validates the <a href=\"modelica://MeshedReservoir.BaseClasses.ExpansionVessel\">
MeshedReservoir.BaseClasses.ExpansionVessel</a> component by connecting it to a mass flow source.
</p>
<p>
The model instantiates two media packages at the top level:
</p>
<ul>
<li>
<code>Medium1</code>: Buildings.Media.Specialized.Water.TemperatureDependentDensity for water
</li>
<li>
<code>Medium2</code>: Modelica.Media.Air.SimpleAir for air
</li>
</ul>
</html>"),
    experiment(StopTime=10800, Tolerance=1e-6),
    __Dymola_Commands(file="modelica://MeshedReservoir/Resources/Scripts/Dymola/BaseClasses/Validation/ExpansionVessel.mos"
        "Simulate and plot"));
end ExpansionVessel;
