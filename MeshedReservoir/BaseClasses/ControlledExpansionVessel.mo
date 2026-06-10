within MeshedReservoir.BaseClasses;
model ControlledExpansionVessel "Controlled expansion vessel"
  extends Buildings.BaseClasses.BaseIcon;

  replaceable package Medium =
    Modelica.Media.Interfaces.PartialMedium "Medium model for water volume"
      annotation (choicesAllMatching = true);
  replaceable package MediumAir =
    Modelica.Media.Interfaces.PartialMedium "Medium model for air volume"
      annotation (choicesAllMatching = true);

  parameter Boolean isMaster
    "Set to true if this is the master expansion vessel. Must have exactly one master in each connected fluid system";

  parameter Modelica.Units.SI.Volume VTot
    "Total volume of the vessel";
  parameter Modelica.Units.SI.Volume VWat_start = VTot/2
    "Volume of liquid stored in the vessel at the start of the simulation";

  // Water volume parameters
  parameter Modelica.Units.SI.Temperature T_start = Medium.T_default
    "Start value of temperature"
    annotation(Dialog(tab = "Initialization"));
  parameter Modelica.Units.SI.AbsolutePressure p_start = Medium.p_default
    "Start value of pressure"
    annotation(Dialog(tab = "Initialization"));

  parameter Real mSetAll(
    final unit="kg")
    "Set point for the mass of all expansion vessels, set to approximately sum of all mTot_start";

  parameter Modelica.Units.SI.Time tCha = 600
    "Time it takes to fully charge the vessel with water or air (at atmospheric pressure)"
    annotation(Dialog(group = "Pump and compressor sizing"));

  parameter Modelica.Units.SI.VolumeFlowRate VAir_flow_nominal = VTot/tCha
    "Design volume flow rate for air compressor"
    annotation(Dialog(group = "Pump and compressor sizing"));
  parameter Modelica.Units.SI.VolumeFlowRate VWat_flow_nominal = VTot/tCha
    "Design volume flow rate for pump compressor"
    annotation(Dialog(group = "Pump and compressor sizing"));

  parameter Real hys(
    min=0.02,
    max=0.3)=0.1 "Hysteresis for comparing input with threshold";
  final parameter Modelica.Units.SI.Mass mTot_start = exp.mTot_start
    "Initial mass of water and air";

  Buildings.Controls.OBC.CDL.Interfaces.RealInput mTotOth(final unit="kg")
    "Total mass of all other expansion vessels in the system"
    annotation (Placement(transformation(extent={{-220,-20},{-180,20}}),
        iconTransformation(extent={{-140,-20},{-100,20}})));
  Modelica.Blocks.Interfaces.RealOutput p(unit="Pa", displayUnit="Pa")
                      "Air pressure in vessel"
    annotation (Placement(transformation(extent={{180,50},{200,70}}),
      iconTransformation(extent={{100,50},{120,70}})));

  Modelica.Blocks.Interfaces.RealOutput m(unit="kg") "Total mass"
    annotation (Placement(transformation(extent={{180,-70},{200,-50}}),
      iconTransformation(extent={{100,-100},{120,-80}})));

  ExpansionVessel exp(
    redeclare final package Medium = Medium,
    redeclare final package MediumAir = MediumAir,
    final VTot=VTot,
    final VWat_start=VWat_start,
    final T_start=T_start,
    final p_start=p_start)
    "Expansion vessel"
    annotation (Placement(transformation(extent={{130,-10},{150,10}})));
  Modelica.Fluid.Interfaces.FluidPort_a portWat(
    redeclare final package Medium = Medium) "Fluid port for water"
    annotation (Placement(transformation(extent={{-10,-110},{10,-90}}),
        iconTransformation(extent={{-10,-110},{10,-90}})));

  Buildings.Controls.OBC.CDL.Reals.Sources.Constant mSetP(k=p_start)
    if isMaster
    "Set point for the pressure of this expansion vessel"
    annotation (Placement(transformation(extent={{-140,100},{-120,120}})));
  Buildings.Controls.OBC.CDL.Reals.Subtract errP(
    u1(final unit="Pa"),
    u2(final unit="Pa"),
    y(final unit="Pa"))
    if isMaster
    "Control error for pressure of this expansion vessel"
    annotation (Placement(transformation(extent={{-100,90},{-80,110}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter errNorP(
    final k=1/p_start)
    if isMaster
    "Normalized error for air control for pressure"
    annotation (Placement(transformation(extent={{-40,90},{-20,110}})));

  Buildings.Controls.OBC.CDL.Reals.Add mAll
    "Total mass of all expansion vessels"
    annotation (Placement(transformation(extent={{-140,-18},{-120,2}})));
  Buildings.Controls.OBC.CDL.Reals.Sources.Constant mAllSetCon(
    k=mSetAll)
    "Set point for all mass of the expansion vessels"
    annotation (Placement(transformation(extent={{-140,-50},{-120,-30}})));
  Buildings.Controls.OBC.CDL.Reals.Sources.Constant mSetExp(k=mTot_start)
    if not isMaster
    "Set point for the mass of this expansion vessel"
    annotation (Placement(transformation(extent={{-140,20},{-120,40}})));

  Buildings.Controls.OBC.CDL.Reals.Subtract errMTot(
    u1(final unit="kg"),
    u2(final unit="kg"),
    y(final unit="kg")) "Control error for total mass in the system"
    annotation (Placement(transformation(extent={{-100,-40},{-80,-20}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter errNorM(final k=1/
        mTot_start) if not isMaster "Normalized error for air control"
    annotation (Placement(transformation(extent={{-40,40},{-20,60}})));
  Buildings.Controls.OBC.CDL.Reals.Subtract errM(
    u1(final unit="kg"),
    u2(final unit="kg"),
    y(final unit="kg"))
    if not isMaster
    "Control error for mass of this expansion vessel"
    annotation (Placement(transformation(extent={{-100,40},{-80,60}})));
  LevelController conAir "Controller for air mass flow rate"
    annotation (Placement(transformation(extent={{10,40},{30,60}})));

  Buildings.Fluid.Sources.MassFlowSource_T souAir(
    redeclare package Medium = MediumAir,
    use_m_flow_in=true,
    nPorts=1)
    "Source/sink for air"
    annotation (Placement(transformation(extent={{112,30},{132,50}})));
  Buildings.Fluid.Sources.MassFlowSource_T souWat(
    redeclare package Medium = Medium,
    use_m_flow_in=true,
    nPorts=1)
    if isMaster
    "Source/sink for water"
    annotation (Placement(transformation(extent={{112,-60},{132,-40}})));

  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter gaiMAir_flow(k=+
        mAir_flow_nominal)
    "Gain for air mass flow rate"
    annotation (Placement(transformation(extent={{50,40},{70,60}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter errNorMTot(final k=1/
        mSetAll) "Normalized error for water control"
    annotation (Placement(transformation(extent={{-40,-40},{-20,-20}})));
  LevelController conWat if isMaster "Controller for water level"
    annotation (Placement(transformation(extent={{10,-40},{30,-20}})));
  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter gaiMWat_flow(k=-
        mWat_flow_nominal)
    if isMaster
    "Gain for air mass flow rate"
    annotation (Placement(transformation(extent={{50,-40},{70,-20}})));
protected
  // Volume parameters
  parameter Modelica.Units.SI.MassFraction X_start[Medium.nX] = Medium.X_default
    "Start value of mass fractions m_i/m for water volume"
    annotation (Dialog(tab="Initialization", enable=Medium.nXi > 0));
  final parameter Medium.ThermodynamicState stateWat_start = Medium.setState_pTX(
      T=T_start,
      p=p_start,
      X=X_start[1:Medium.nXi]) "Water medium state at start values";
  final parameter Modelica.Units.SI.Density rhoWat_start=Medium.density(state=
      stateWat_start) "Water density, used to compute start and guess values";

  final parameter MediumAir.ThermodynamicState stateAir_start = MediumAir.setState_pTX(
      T=T_start,
      p=p_start,
      X=MediumAir.X_default) "Air medium state at start values";
  final parameter Modelica.Units.SI.Density rhoAir_start=MediumAir.density(state=
      stateAir_start) "Air density, used to compute start and guess values";

  parameter Modelica.Units.SI.MassFlowRate mAir_flow_nominal = VAir_flow_nominal*rhoAir_start
    "Design volume flow rate for air compressor";
  parameter Modelica.Units.SI.MassFlowRate mWat_flow_nominal = VWat_flow_nominal*rhoWat_start
    "Design volume flow rate for pump";

equation
  connect(exp.portWat, portWat)
    annotation (Line(points={{140,-10},{140,-80},{0,-80},{0,-100}},
                                                color={0,127,255}));
  connect(souWat.ports[1], exp.portWat)
    annotation (Line(points={{132,-50},{140,-50},{140,-10}},
                                                         color={0,127,255}));
  connect(souAir.ports[1], exp.portAir)
    annotation (Line(points={{132,40},{140,40},{140,10}},
                                                      color={0,127,255}));
  connect(exp.p, p) annotation (Line(points={{151,6},{160,6},{160,60},{190,60}},
        color={0,0,127}));
  connect(exp.m, m) annotation (Line(points={{151,-9},{160,-9},{160,-60},{190,-60}},
        color={0,0,127}));
  connect(mTotOth, mAll.u1) annotation (Line(points={{-200,0},{-172,0},{-172,-2},
          {-142,-2}}, color={0,0,127}));
  connect(exp.m, mAll.u2) annotation (Line(points={{151,-9},{160,-9},{160,-60},{
          -160,-60},{-160,-14},{-142,-14}},
                                     color={0,0,127}));
  connect(errNorM.u, errM.y)
    annotation (Line(points={{-42,50},{-78,50}}, color={0,0,127}));
  connect(gaiMAir_flow.y, souAir.m_flow_in) annotation (Line(points={{72,50},{86,
          50},{86,48},{110,48}}, color={0,0,127}));
  connect(conAir.y, gaiMAir_flow.u)
    annotation (Line(points={{32,50},{48,50}}, color={0,0,127}));
  connect(errNorM.y, conAir.err)
    annotation (Line(points={{-18,50},{8,50}}, color={0,0,127}));
  connect(conWat.y, gaiMWat_flow.u)
    annotation (Line(points={{32,-30},{48,-30}}, color={0,0,127}));
  connect(errNorMTot.y, conWat.err)
    annotation (Line(points={{-18,-30},{8,-30}}, color={0,0,127}));
  connect(gaiMWat_flow.y, souWat.m_flow_in) annotation (Line(points={{72,-30},{90,
          -30},{90,-42},{110,-42}}, color={0,0,127}));
  connect(errMTot.y, errNorMTot.u)
    annotation (Line(points={{-78,-30},{-42,-30}}, color={0,0,127}));
  connect(exp.m, errM.u1) annotation (Line(points={{151,-9},{160,-9},{160,-60},{
          -160,-60},{-160,56},{-102,56}}, color={0,0,127}));
  connect(mSetExp.y, errM.u2) annotation (Line(points={{-118,30},{-110,30},{-110,
          44},{-102,44}}, color={0,0,127}));
  connect(mAllSetCon.y, errMTot.u2) annotation (Line(points={{-118,-40},{-110,-40},
          {-110,-36},{-102,-36}}, color={0,0,127}));
  connect(mAll.y, errMTot.u1) annotation (Line(points={{-118,-8},{-110,-8},{-110,
          -24},{-102,-24}}, color={0,0,127}));
  connect(mSetP.y, errP.u1) annotation (Line(points={{-118,110},{-110,110},{-110,
          106},{-102,106}}, color={0,0,127}));
  connect(errP.u2, exp.p) annotation (Line(points={{-102,94},{-112,94},{-112,80},
          {160,80},{160,6},{151,6}}, color={0,0,127}));
  connect(errP.y, errNorP.u)
    annotation (Line(points={{-78,100},{-42,100}}, color={0,0,127}));
  connect(errNorP.y, conAir.err) annotation (Line(points={{-18,100},{-10,100},{-10,
          50},{8,50}}, color={0,0,127}));
  annotation(
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},
      {100,100}}),
      graphics={
        Line(points={{-44,0},{-100,0}}, color={0,0,0}),
        Rectangle(
          extent={{-44,80},{60,-80}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-32,70},{50,-70}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-32,DynamicSelect(0, -70 + 140*exp.hNor)},{50,-70}},
          lineColor={0,0,0},
          fillColor={28,108,200},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{2,-80},{-2,-90}},
          lineColor={0,0,255},
          pattern=LinePattern.None,
          fillColor={0,0,127},
          fillPattern=FillPattern.Solid),
        Line(points={{100,60},{50,60}}, color={0,0,0}),
        Line(points={{50,-90},{50,-80}}, color={0,0,0}),
        Text(
          extent={{62,94},{96,66}},
          textColor={0,0,255},
          textString="p"),
        Text(
          extent={{64,-58},{98,-86}},
          textColor={0,0,255},
          textString="m"),
        Line(points={{100,-90},{50,-90}},
                                        color={0,0,0}),
        Rectangle(
          extent={{-90,10},{-60,-10}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Line(points={{-90,-10},{-78,0}}, color={0,0,0}),
        Line(points={{-90,10},{-78,0}}, color={0,0,0}),
        Text(
          visible=isMaster,
          extent={{-26,114},{42,72}},
          textColor={0,0,0},
          textString="master"),
        Rectangle(
          extent={{DynamicSelect(-76, -75 + 15*min(0, conAir.y)),10},{DynamicSelect(-60, -75 + 15*max(0, conAir.y)),20}},
          lineColor={0,0,0},
          pattern=LinePattern.None,
          fillColor={0,140,72},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent=DynamicSelect({{-76,-20},{-60,-10}}, if isMaster then {{-75 + 15*min(0, conWat.y),-20},{-75 + 15*max(0, conWat.y),-10}} else {{-75,-20},{-75,-10}}),
          lineColor={0,0,0},
          pattern=LinePattern.None,
          fillColor={28,108,200},
          fillPattern=FillPattern.Solid)}),
        Diagram(
        coordinateSystem(preserveAspectRatio=false, extent={{-180,-100},{180,140}})));


end ControlledExpansionVessel;
