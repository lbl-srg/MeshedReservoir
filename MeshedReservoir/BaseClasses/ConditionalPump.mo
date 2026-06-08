within MeshedReservoir.BaseClasses;
model ConditionalPump "Model that allows adding or removing a pump"
  extends Buildings.Fluid.Interfaces.PartialTwoPortTransport;

  parameter Boolean have_pump "if true, model has a pump, otherwise it is just a lossless pipe";
  parameter Modelica.Units.SI.MassFlowRate m_flow_nominal
    "Nominal mass flow rate for configuration of pressure curve";
  parameter Modelica.Units.SI.PressureDifference dp_nominal(displayUnit="Pa")
    "Nominal pressure head for configuration of pressure curve";

  Modelica.Blocks.Interfaces.RealInput y(
    min=0,
    max=1,
    final unit="1") if have_pump
  "Constant normalized rotational speed"
    annotation (Placement(transformation(extent={{-140,60},{-100,100}}),
        iconTransformation(extent={{-140,60},{-100,100}})));
  Buildings.Fluid.Movers.Preconfigured.SpeedControlled_y mov(
    redeclare package Medium = Medium,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial,
    addPowerToMedium=false,
    use_riseTime=false,
    m_flow_nominal=m_flow_nominal,
    dp_nominal=dp_nominal)             if have_pump
    "Pump"
    annotation (Placement(transformation(extent={{-10,30},{10,50}})));

  Buildings.Fluid.FixedResistances.LosslessPipe pip(
    redeclare package Medium = Medium) if not have_pump
    "Pipe"
    annotation (Placement(transformation(extent={{-10,-50},{10,-30}})));

equation
  connect(mov.y, y)
    annotation (Line(points={{0,52},{0,80},{-120,80}}, color={0,0,127}));
  connect(port_a, mov.port_a) annotation (Line(points={{-100,0},{-60,0},{-60,40},
          {-10,40}}, color={0,127,255}));
  connect(mov.port_b, port_b) annotation (Line(points={{10,40},{60,40},{60,0},{100,
          0}}, color={0,127,255}));
  connect(port_a, pip.port_a) annotation (Line(points={{-100,0},{-60,0},{-60,-40},
          {-10,-40}}, color={0,127,255}));
  connect(pip.port_b, port_b) annotation (Line(points={{10,-40},{60,-40},{60,0},
          {100,0}}, color={0,127,255}));
  annotation (
    defaultComponentName="pum",
    Icon(graphics={Ellipse(
    visible=have_pump,
          extent={{-60,60},{60,-60}},
          lineColor={0,0,0},
    lineThickness=0.5),
    Polygon(
      visible=have_pump,
          points={{0,60},{0,-60},{60,0},{0,60}},
          lineColor={0,0,0},
          lineThickness=0.5,
          fillColor={0,0,0},
      fillPattern=FillPattern.Solid),
        Line(
          visible=have_pump,
          points={{-100,80},{0,80},{0,60}},
          color={0,0,0},
          thickness=0.5,
          pattern=LinePattern.Dash),
    Rectangle(
      visible=not have_pump,
          extent={{-60,10},{60,-8}},
          lineColor={0,0,0},
          lineThickness=0.5,
          fillColor={0,0,0},
          fillPattern=FillPattern.None),
        Line(
          points={{-90,0},{-60,0}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{60,0},{90,0}},
          color={0,0,0},
          thickness=0.5)}));
end ConditionalPump;
