within MeshedReservoir;
model SingleLoop
  final package Medium = Buildings.Media.Specialized.Water.TemperatureDependentDensity
    "Medium model for water";
  parameter Modelica.Units.SI.MassFlowRate m_flow_nominal = 685
    "Design mass flow rate";
  parameter Modelica.Units.SI.PressureDifference dp_nominal = 479E3
    "Design pressure difference";
  parameter Modelica.Units.SI.Volume VLoo = 3500 * 0.505^2*Modelica.Constants.pi/4
    "Water volume in the loop";
  parameter Modelica.Units.SI.Volume VBor =
    (375 * 2 * 120 + 2025 * 2 * 85)  * (0.016-0.0029)^2*Modelica.Constants.pi
    "Water volume in borefield";

  final parameter Modelica.Units.SI.Density rho10 =
    Medium.density(
      Medium.setState_pTX(
      p=1E5,
      T=283.15,
      X=Medium.X_default))
      "Density at 10 degC";
  final parameter Modelica.Units.SI.Density rho30 =
    Medium.density(
      Medium.setState_pTX(
      p=1E5,
      T=303.15,
      X=Medium.X_default))
      "Density at 30 degC";

  parameter Modelica.Units.SI.Volume VTheExp = (VLoo+VBor)*(rho10-rho30)/rho30
    "Thermal expansion of water";
  parameter Modelica.Units.SI.Volume VTotExp = VTheExp*1.1
    "Total volume of expansion vessel";

  parameter Boolean have_pumpUpstream = true
    "Set to true to have a pump upstream of the loop connection";
  parameter Boolean have_expansionVesselUpstream = true
    "Set to true to have a expansion vessel upstream of the loop connection";

  parameter Real yPumRamp[:,:]=[
    3600,0;
    7200,m_flow_nominal]
    "Control schedule, pump off for one hour, then ramping up for 1 hour, then full speed";

  Modelica.Fluid.Interfaces.FluidPort_a port_1(redeclare package Medium =
        Medium) "Fluid port"
    annotation (Placement(transformation(extent={{-30,110},{-10,130}})));
  Modelica.Fluid.Interfaces.FluidPort_a port_2(redeclare package Medium =
        Medium) "Fluid port"
    annotation (Placement(transformation(extent={{10,110},{30,130}})));
  Modelica.Fluid.Interfaces.FluidPort_a port_3(redeclare package Medium =
        Medium) "Fluid port"
    annotation (Placement(transformation(extent={{-50,-110},{-30,-90}})));
  Modelica.Fluid.Interfaces.FluidPort_a port_4(redeclare package Medium =
        Medium) "Fluid port"
    annotation (Placement(transformation(extent={{-90,-110},{-70,-90}})));

  model Junction = Buildings.Fluid.FixedResistances.Junction(
    redeclare final package Medium=Medium,
    final energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState,
    final m_flow_nominal=m_flow_nominal*{1, 1, 1},
    final dp_nominal={1000,1000,1000}) "Configured model of a fluid junction";
  model ConditionalPump = BaseClasses.ConditionalPump(
    redeclare final package Medium = Medium,
    final m_flow_nominal=m_flow_nominal,
    final dp_nominal=dp_nominal) "Conditional pump";
  model Volume = Buildings.Fluid.MixingVolumes.MixingVolume(
    redeclare package Medium = Medium,
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    mSenFac=1,
    m_flow_nominal=m_flow_nominal,
    V=(VLoo+VBor)) "Mixing volume";
  model ExpansionVessel = BaseClasses.ExpansionVessel(
    redeclare final package Medium = Medium,
    redeclare final package MediumAir = Modelica.Media.Air.SimpleAir,
    final VTot=VTotExp) "Expansion vessel";
  model PressureDrop = Buildings.Fluid.FixedResistances.PressureDrop(
      redeclare final package Medium = Medium,
      final m_flow_nominal=m_flow_nominal,
      final dp_nominal=dp_nominal-4*1000) "Flow resistance of loop";
  ConditionalPump pumUp(have_pump=have_pumpUpstream) "Upstream pump"
    annotation (Placement(transformation(extent={{-60,30},{-40,50}})));
  ConditionalPump pumDow(have_pump=not have_pumpUpstream) "Downstream pump"
    annotation (Placement(transformation(extent={{100,30},{120,50}})));

  ExpansionVessel expUp
    if have_expansionVesselUpstream "Expansion vessel upstream"
    annotation (Placement(transformation(extent={{-130,50},{-110,70}})));
  ExpansionVessel expDow if not have_expansionVesselUpstream
    "Expansion vessel downstream"
    annotation (Placement(transformation(extent={{130,50},{150,70}})));

  Junction jun11
   "Junction"
    annotation (Placement(transformation(extent={{-30,50},{-10,30}})));
  Junction jun12
    "Junction"
    annotation (Placement(transformation(extent={{10,50},{30,30}})));
  Junction jun13
   "Junction"
    annotation (Placement(transformation(extent={{-30,-50},{-50,-30}})));
  Junction jun14
    "Junction"
    annotation (Placement(transformation(extent={{-70,-50},{-90,-30}})));

  Volume vol(nPorts=2) "Fluid volume"
    annotation (Placement(transformation(extent={{12,-40},{32,-20}})));
  PressureDrop res1 "Flow resistance"
    annotation (Placement(transformation(extent={{80,-50},{100,-30}})));

  Buildings.Controls.OBC.CDL.Reals.Sources.TimeTable yPum(
    table=yPumRamp,
    smoothness=Buildings.Controls.OBC.CDL.Types.Smoothness.LinearSegments,
    extrapolation=Buildings.Controls.OBC.CDL.Types.Extrapolation.HoldLastPoint)
    "Time schedule for pump operation"
    annotation (Placement(transformation(extent={{-100,70},{-80,90}})));

equation
  connect(jun11.port_2, jun12.port_1)
    annotation (Line(points={{-10,40},{10,40}}, color={0,127,255}));
  connect(jun12.port_2, pumDow.port_a)
    annotation (Line(points={{30,40},{100,40}}, color={0,127,255}));
  connect(pumUp.port_a,expUp. portWat) annotation (Line(points={{-60,40},{-120,40},
          {-120,50}}, color={0,127,255}));
  connect(pumDow.port_b, res1.port_b) annotation (Line(points={{120,40},{140,40},
          {140,-40},{100,-40}}, color={0,127,255}));
  connect(res1.port_a, vol.ports[1])
    annotation (Line(points={{80,-40},{21,-40}}, color={0,127,255}));
  connect(vol.ports[2], jun13.port_1)
    annotation (Line(points={{23,-40},{-30,-40}}, color={0,127,255}));
  connect(jun13.port_2, jun14.port_1)
    annotation (Line(points={{-50,-40},{-70,-40}}, color={0,127,255}));
  connect(jun14.port_2,pumUp. port_a) annotation (Line(points={{-90,-40},{-120,-40},
          {-120,40},{-60,40}},   color={0,127,255}));
  connect(pumDow.port_b, expDow.portWat)
    annotation (Line(points={{120,40},{140,40},{140,50}}, color={0,127,255}));
  connect(yPum.y[1], pumUp.mSet_flow) annotation (Line(points={{-78,80},{-70,80},
          {-70,48},{-62,48}}, color={0,0,127}));
  connect(yPum.y[1], pumDow.mSet_flow) annotation (Line(points={{-78,80},{90,80},
          {90,48},{98,48}}, color={0,0,127}));
  connect(pumUp.port_b, jun11.port_1)
    annotation (Line(points={{-40,40},{-30,40}}, color={0,127,255}));
  connect(jun11.port_3, port_1)
    annotation (Line(points={{-20,50},{-20,120}}, color={0,127,255}));
  connect(jun12.port_3, port_2)
    annotation (Line(points={{20,50},{20,120}}, color={0,127,255}));
  connect(jun13.port_3, port_3)
    annotation (Line(points={{-40,-50},{-40,-100}}, color={0,127,255}));
  connect(jun14.port_3, port_4)
    annotation (Line(points={{-80,-50},{-80,-100}}, color={0,127,255}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-180,-100},
            {180,120}}), graphics={
        Rectangle(
          extent={{-180,120},{180,-100}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Line(
          points={{-120,-60},{122,-60}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{-120,80},{122,80}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{-120,80},{-120,-60}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{122,80},{122,-60}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{-20,120},{-20,80}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{20,120},{20,80}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{-40,-60},{-40,-100}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{-80,-60},{-80,-100}},
          color={0,0,0},
          thickness=0.5)}),                                      Diagram(
        coordinateSystem(preserveAspectRatio=false, extent={{-180,-100},{180,120}})),
    experiment(
      StopTime=10800,
      Tolerance=1e-05,
      __Dymola_Algorithm="Cvode"));
end SingleLoop;
