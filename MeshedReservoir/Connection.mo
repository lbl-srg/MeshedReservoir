within MeshedReservoir;
model Connection "Connection between two loops"
  replaceable package Medium = Buildings.Media.Specialized.Water.TemperatureDependentDensity
    "Medium model for water";

  parameter Modelica.Units.SI.MassFlowRate m_flow_nominal
    "Design mass flow rate";
  final parameter Modelica.Units.SI.PressureDifference dp_nominal = 4 * dpJun_nominal
    "Design pressure difference";

  parameter Modelica.Units.SI.PressureDifference dpJun_nominal
    "Design pressure drop of one leg of a junction";

  Modelica.Fluid.Interfaces.FluidPort_a port_1(
    redeclare package Medium = Medium)
    "Fluid port"
    annotation (Placement(transformation(extent={{-30,90},{-10,110}}),
        iconTransformation(extent={{-30,90},{-10,110}})));
  Modelica.Fluid.Interfaces.FluidPort_a port_2(
    redeclare package Medium = Medium)
    "Fluid port"
    annotation (Placement(transformation(extent={{10,90},{30,110}}),
        iconTransformation(extent={{10,90},{30,110}})));
  Modelica.Fluid.Interfaces.FluidPort_a port_3(
    redeclare package Medium = Medium)
    "Fluid port"
    annotation (Placement(transformation(extent={{10,-110},{30,-90}})));
  Modelica.Fluid.Interfaces.FluidPort_a port_4(
    redeclare package Medium = Medium)
    "Fluid port"
    annotation (Placement(transformation(extent={{-30,-110},{-10,-90}})));

  Buildings.Fluid.Movers.Preconfigured.FlowControlled_m_flow mov(
    redeclare package Medium = Medium,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial,
    addPowerToMedium=false,
    use_riseTime=false,
    m_flow_nominal=m_flow_nominal,
    dp_nominal=dp_nominal)
    "Pump"
    annotation (Placement(transformation(extent={{-10,-10},{10,10}},
        rotation=90,
        origin={-20,0})));
  Modelica.Blocks.Interfaces.IntegerInput ySetWasHea
    "If 1, add heat to the loop, if -1, remove heat from the loop" annotation (
      Placement(transformation(extent={{-220,-20},{-180,20}}),
        iconTransformation(extent={{-120,-10},{-100,10}})));
  Buildings.Controls.OBC.CDL.Integers.Equal intEqu
    annotation (Placement(transformation(extent={{-120,-10},{-100,10}})));
  Buildings.Controls.OBC.CDL.Integers.Sources.Constant zer(k=0) "Output zero"
    annotation (Placement(transformation(extent={{-160,-40},{-140,-20}})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToReal ySetPum(realTrue=0,
      realFalse=m_flow_nominal) "Pump set point"
    annotation (Placement(transformation(extent={{-80,-10},{-60,10}})));
equation
  connect(zer.y, intEqu.u2) annotation (Line(points={{-138,-30},{-130,-30},{-130,
          -8},{-122,-8}}, color={255,127,0}));
  connect(intEqu.u1, ySetWasHea)
    annotation (Line(points={{-122,0},{-200,0}}, color={255,127,0}));
  connect(ySetPum.u, intEqu.y)
    annotation (Line(points={{-82,0},{-98,0}}, color={255,0,255}));
  connect(ySetPum.y, mov.m_flow_in)
    annotation (Line(points={{-58,0},{-32,0}}, color={0,0,127}));
  connect(port_1, mov.port_b)
    annotation (Line(points={{-20,100},{-20,10}}, color={0,127,255}));
  connect(mov.port_a, port_4)
    annotation (Line(points={{-20,-10},{-20,-100}}, color={0,127,255}));
  connect(port_2, port_3)
    annotation (Line(points={{20,100},{20,-100}}, color={0,127,255}));
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
      graphics={
        Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Line(
          points={{-20,100},{-20,-100}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{20,100},{20,-100}},
          color={0,0,0},
          thickness=0.5),
                   Ellipse(
          extent={{-50,30},{10,-30}},
          lineColor={0,0,0},
    lineThickness=0.5,
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
    Polygon(
          points={{-20,30},{-50,0},{10,0},{-20,30}},
          lineColor={0,0,0},
          lineThickness=0.5,
          fillColor={0,0,0},
      fillPattern=FillPattern.Solid)}),
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-180,-100},{180,
            100}})));
end Connection;
