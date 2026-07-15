within MeshedReservoir;
model SingleLoop "Single loop with expansion vessel"
  replaceable package Medium = Buildings.Media.Specialized.Water.TemperatureDependentDensity
    "Medium model for water";
  final package MediumAir = Modelica.Media.Air.SimpleAir
    "Medium model for air";

  parameter Modelica.Units.SI.AbsolutePressure pMax=1600000
    "Maximum pressure, above which the simulation stops with an assertion"
    annotation (Dialog(group="Static pressures"));
  parameter Modelica.Units.SI.AbsolutePressure pMin=120000
    "Minimum pressure, below which the simulation stops with an assertion"
    annotation (Dialog(group="Static pressures"));
  parameter Modelica.Units.SI.AbsolutePressure p_start=600000
    "Start value of pressure"
    annotation (Dialog(group="Static pressures"));

  parameter Modelica.Units.SI.MassFlowRate m_flow_nominal = 685
    "Design mass flow rate";
  parameter Modelica.Units.SI.PressureDifference dp_nominal = 479E3
    "Design pressure difference";
  parameter Modelica.Units.SI.PressureDifference dpJun_nominal
    "Design pressure drop of one leg of a junction";

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

  parameter MeshedReservoir.Configuration configuration = MeshedReservoir.Configuration.idealPressure
    "Configuration of the loop";

  parameter Real pumSch[:,:]=[
    3600, 0;
    7200, m_flow_nominal]
    "Control schedule, pump off for one hour, then ramping up for 1 hour, then full speed";

  parameter Boolean isMaster
    "Set to true if this is the master expansion vessel. Must have exactly one master in each connected fluid system";
  parameter Real mSetAll
    "Set point for the mass of all expansion vessels, set to approximately sum of all mTot_start";

  parameter Boolean addHeat = false
    "Set to true to add heat";
  parameter Modelica.Units.SI.HeatFlowRate Q_flow = vol.V * rho10 * 4200 * (30-10) / (3*3600)
    "Heat flow rate to heat up volume from 20 to 30 degC in 3 hours";

  parameter Modelica.Units.SI.HeatFlowRate QWasHea_nominal
    "Gain for waste (or excess) heat flow rate transfer";

  Modelica.Blocks.Interfaces.RealOutput pOut(
    final unit="Pa")
    "Outlet pressure"
    annotation(Placement(transformation(extent={{180,80},{200,100}})));
  Modelica.Blocks.Interfaces.RealOutput pIn(
    final unit="Pa")
    "Inlet pressure"
    annotation(Placement(transformation(extent={{180,100},{200,120}})));

  Buildings.Controls.OBC.CDL.Interfaces.RealInput mAll
    "Total mass of all expansion vessels in the system"
    annotation(Placement(transformation(extent={{-220,-20},{-180,20}})));
  Modelica.Blocks.Interfaces.RealOutput m
    "Mass of expansion vessel"
    annotation(Placement(transformation(extent={{180,50},{200,70}})));

  Modelica.Fluid.Interfaces.FluidPort_a port_1(
    redeclare package Medium = Medium)
    "Fluid port"
    annotation(Placement(transformation(extent={{-30,170},{-10,190}}),
      iconTransformation(extent={{-30,110},{-10,130}})));
  Modelica.Fluid.Interfaces.FluidPort_a port_2(
    redeclare package Medium = Medium)
    "Fluid port"
    annotation(Placement(transformation(extent={{10,170},{30,190}}),
      iconTransformation(extent={{10,110},{30,130}})));
  Modelica.Fluid.Interfaces.FluidPort_a port_3(
    redeclare package Medium = Medium)
    "Fluid port"
    annotation(Placement(transformation(extent={{10,-110},{30,-90}})));
  Modelica.Fluid.Interfaces.FluidPort_a port_4(
    redeclare package Medium = Medium)
    "Fluid port"
    annotation(Placement(transformation(extent={{-30,-110},{-10,-90}})));

  model Junction = Buildings.Fluid.FixedResistances.Junction(
    redeclare final package Medium=Medium,
    final energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState,
    final m_flow_nominal=m_flow_nominal*{1, 1, 1},
    final dp_nominal={dpJun_nominal,dpJun_nominal,dpJun_nominal}) "Configured model of a fluid junction";
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
  model ExpansionVessel = BaseClasses.ControlledExpansionVessel(
    redeclare package Medium = Medium,
    redeclare package MediumAir = MediumAir,
    final isMaster=isMaster,
    final VTot=VTotExp,
    final mSetAll=mSetAll,
    final p_start=p_start,
    final pMin=pMin,
    final pMax=pMax) "Expansion vessel";
  model PressureDrop = Buildings.Fluid.FixedResistances.PressureDrop(
      redeclare final package Medium = Medium,
      final m_flow_nominal=m_flow_nominal) "Flow resistance of loop";
  ConditionalPump pumUp(
    have_pump=(configuration == MeshedReservoir.Configuration.highPressure))
    "Upstream pump"
    annotation(Placement(transformation(extent={{-60,30},{-40,50}})));
  ConditionalPump pumDow(
    have_pump=not (configuration == MeshedReservoir.Configuration.highPressure))
    "Downstream pump"
    annotation(Placement(transformation(extent={{100,30},{120,50}})));

  ExpansionVessel expUp
    if not (configuration == MeshedReservoir.Configuration.lowPressure)
    "Expansion vessel upstream"
    annotation(Placement(transformation(extent={{-130,58},{-110,78}})));
  ExpansionVessel expDow
    if configuration == MeshedReservoir.Configuration.lowPressure
    "Expansion vessel downstream"
    annotation(Placement(transformation(extent={{130,58},{150,78}})));

  Junction jun11
    "Junction"
    annotation(Placement(transformation(extent={{-30,50},{-10,30}})));
  Junction jun12
    "Junction"
    annotation(Placement(transformation(extent={{10,50},{30,30}})));
  Junction jun13
    "Junction"
    annotation(Placement(transformation(extent={{30,-70},{10,-50}})));
  Junction jun14
    "Junction"
    annotation(Placement(transformation(extent={{-10,-70},{-30,-50}})));

  Volume vol(nPorts=2)
    "Fluid volume"
    annotation(Placement(transformation(extent={{-10,10},{10,-10}},
      rotation=270,
      origin={130,0})));
  PressureDrop res1(
    final dp_nominal=if not (configuration == MeshedReservoir.Configuration.lowPressure)
      then dp_nominal-4*dpJun_nominal else 0)
    "Flow resistance"
    annotation(Placement(transformation(extent={{100,-70},{80,-50}})));

  PressureDrop res2(
    final dp_nominal=if (configuration == MeshedReservoir.Configuration.lowPressure)
      then dp_nominal-4*dpJun_nominal else 0)
    "Flow resistance"
    annotation(Placement(transformation(extent={{-60,-70},{-80,-50}})));

  Buildings.Controls.OBC.CDL.Reals.Sources.TimeTable yPum(
    table=pumSch,
    smoothness=Buildings.Controls.OBC.CDL.Types.Smoothness.LinearSegments,
    extrapolation=Buildings.Controls.OBC.CDL.Types.Extrapolation.Periodic)
    "Time schedule for pump operation"
    annotation(Placement(transformation(extent={{-100,70},{-80,90}})));

  Modelica.Blocks.Interfaces.RealOutput pExp "Air pressure in vessel"
    annotation(Placement(transformation(extent={{180,-50},{200,-30}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow heaSou if addHeat
    "Heat source"
    annotation(Placement(transformation(extent={{60,4},{80,24}})));

  Buildings.Controls.OBC.CDL.Reals.Sources.TimeTable yHea(
    table=[0,0; 54,1; 57,0],
    smoothness=Buildings.Controls.OBC.CDL.Types.Smoothness.ConstantSegments,
    timeScale=3600) if addHeat
    "Time schedule for heat input"
    annotation(Placement(transformation(extent={{0,4},{20,24}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter gai(k=Q_flow) if addHeat
    "Gain for heat flow rate"
    annotation(Placement(transformation(extent={{28,4},{48,24}})));
  Buildings.Controls.OBC.CDL.Reals.Max max1
    annotation(Placement(transformation(extent={{120,120},{140,140}})));
  Buildings.Controls.OBC.CDL.Reals.Min min1
    annotation(Placement(transformation(extent={{120,150},{140,170}})));
  Modelica.Blocks.Interfaces.IntegerInput ySetWasHea
    "If 1, add heat to the loop, if -1, remove heat from the loop"
    annotation(Placement(transformation(extent={{-220,-80},{-180,-40}}),
      iconTransformation(extent={{-220,-80},{-180,-40}})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow wasHeaSou
    "Waste heat source"
    annotation(Placement(transformation(extent={{62,-30},{82,-10}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter gaiWasHea(k=
        QWasHea_nominal) "Gain for waste heat flow rate"
    annotation(Placement(transformation(extent={{30,-30},{50,-10}})));

  Buildings.Controls.OBC.CDL.Conversions.IntegerToReal intToRea
    "Type conversion to activate waste heat"
    annotation(Placement(transformation(extent={{0,-30},{20,-10}})));
equation
  connect(jun11.port_2, jun12.port_1)
    annotation (Line(points={{-10,40},{10,40}}, color={0,127,255}));
  connect(jun12.port_2, pumDow.port_a)
    annotation (Line(points={{30,40},{100,40}}, color={0,127,255}));
  connect(pumUp.port_a, expUp.portWat) annotation (Line(points={{-60,40},{-120,
          40},{-120,58}},
                      color={0,127,255}));
  connect(jun13.port_2, jun14.port_1)
    annotation (Line(points={{10,-60},{-10,-60}},  color={0,127,255}));
  connect(pumDow.port_b, expDow.portWat)
    annotation (Line(points={{120,40},{140,40},{140,58}}, color={0,127,255}));
  connect(yPum.y[1], pumUp.mSet_flow) annotation (Line(points={{-78,80},{-70,80},
          {-70,48},{-62,48}}, color={0,0,127}));
  connect(yPum.y[1], pumDow.mSet_flow) annotation (Line(points={{-78,80},{90,80},
          {90,48},{98,48}}, color={0,0,127}));
  connect(pumUp.port_b, jun11.port_1)
    annotation (Line(points={{-40,40},{-30,40}}, color={0,127,255}));
  connect(jun11.port_3, port_1)
    annotation (Line(points={{-20,50},{-20,180}}, color={0,127,255}));
  connect(jun12.port_3, port_2)
    annotation (Line(points={{20,50},{20,180}}, color={0,127,255}));
  connect(jun13.port_3, port_3)
    annotation (Line(points={{20,-70},{20,-100}},   color={0,127,255}));
  connect(jun14.port_3, port_4)
    annotation (Line(points={{-20,-70},{-20,-100}}, color={0,127,255}));
  connect(expDow.m, m) annotation (Line(points={{151,59},{170,59},{170,60},{190,
          60}}, color={0,0,127}));
  connect(expUp.m, m) annotation (Line(points={{-109,59},{-102,59},{-102,102},{
          170,102},{170,60},{190,60}},
                                   color={0,0,127}));
  connect(expUp.mAll, mAll) annotation (Line(points={{-132,68},{-150,68},{-150,
          0},{-200,0}},
                     color={0,0,127}));
  connect(mAll, expDow.mAll) annotation (Line(points={{-200,0},{-150,0},{-150,
          96},{120,96},{120,68},{128,68}},
                                        color={0,0,127}));
  connect(expDow.p, pExp) annotation (Line(points={{151,74},{160,74},{160,-40},
          {190,-40}}, color={0,0,127}));
  connect(pExp, expUp.p) annotation (Line(points={{190,-40},{160,-40},{160,108},
          {-106,108},{-106,74},{-109,74}}, color={0,0,127}));
  connect(heaSou.port, vol.heatPort) annotation (Line(points={{80,14},{130,14},{
          130,10}},  color={191,0,0}));
  connect(jun14.port_2, res2.port_a)
    annotation (Line(points={{-30,-60},{-60,-60}}, color={0,127,255}));
  connect(res2.port_b, pumUp.port_a) annotation (Line(points={{-80,-60},{-120,-60},
          {-120,40},{-60,40}}, color={0,127,255}));
  connect(pumDow.port_b, vol.ports[1])
    annotation (Line(points={{120,40},{140,40},{140,1}}, color={0,127,255}));
  connect(res1.port_a, vol.ports[2]) annotation (Line(points={{100,-60},{140,-60},
          {140,-1}}, color={0,127,255}));
  connect(res1.port_b, jun13.port_1)
    annotation (Line(points={{80,-60},{30,-60}}, color={0,127,255}));
  connect(heaSou.Q_flow, gai.y)
    annotation (Line(points={{60,14},{50,14}}, color={0,0,127}));
  connect(yHea.y[1], gai.u)
    annotation (Line(points={{22,14},{26,14}}, color={0,0,127}));
  connect(min1.y, pIn) annotation (Line(points={{142,160},{174,160},{174,110},{
          190,110}}, color={0,0,127}));
  connect(max1.y, pOut) annotation (Line(points={{142,130},{172,130},{172,90},{
          190,90}}, color={0,0,127}));
  connect(pumUp.pIn, min1.u1) annotation (Line(points={{-39,48},{-30,48},{-30,
          166},{118,166}}, color={0,0,127}));
  connect(pumDow.pIn, min1.u2) annotation (Line(points={{121,48},{126,48},{126,
          58},{102,58},{102,154},{118,154}}, color={0,0,127}));
  connect(pumUp.pOut, max1.u1) annotation (Line(points={{-39,46},{-28,46},{-28,
          136},{118,136}}, color={0,0,127}));
  connect(pumDow.pOut, max1.u2) annotation (Line(points={{121,46},{128,46},{128,
          60},{104,60},{104,124},{118,124}}, color={0,0,127}));
  connect(gaiWasHea.y, wasHeaSou.Q_flow)
    annotation (Line(points={{52,-20},{62,-20}}, color={0,0,127}));
  connect(wasHeaSou.port, vol.heatPort) annotation (Line(points={{82,-20},{100,-20},
          {100,14},{130,14},{130,10}}, color={191,0,0}));
  connect(gaiWasHea.u, intToRea.y)
    annotation (Line(points={{28,-20},{22,-20}}, color={0,0,127}));
  connect(ySetWasHea, intToRea.u) annotation (Line(points={{-200,-60},{-140,-60},
          {-140,-20},{-2,-20}}, color={255,127,0}));
    annotation(
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-180,-100},{180,120}}),
      graphics={
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
          points={{20,-60},{20,-100}},
          color={0,0,0},
          thickness=0.5),
        Line(
          points={{-20,-60},{-20,-100}},
          color={0,0,0},
          thickness=0.5)}),                                      Diagram(
        coordinateSystem(preserveAspectRatio=false, extent={{-180,-100},{180,180}})));
end SingleLoop;
