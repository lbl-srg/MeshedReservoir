within MeshedReservoir.Examples;
model ThreeLoops "Three reservoir loops connected"
  extends Modelica.Icons.Example;

  replaceable package Medium = Buildings.Media.Specialized.Water.TemperatureDependentDensity
    "Medium model for water";
  parameter Boolean use_wasteHeat = true
    "Set to true to enable use of waste heat";

  parameter Integer conInd = 2
    "Index for configuration (1: highPressure, 2: idealPressure, 3: lowPressure)";

  parameter Modelica.Units.SI.AbsolutePressure pMax=18E5
    "Maximum pressure, above which the simulation stops with an assertion"
    annotation(Dialog(group="Static pressures"));
  parameter Modelica.Units.SI.AbsolutePressure pMin=2E5
    "Minimum pressure, below which the simulation stops with an assertion"
    annotation(Dialog(group="Static pressures"));
  parameter Modelica.Units.SI.AbsolutePressure p_start=
    if configuration == MeshedReservoir.Configuration.highPressure then
      3E5
    elseif configuration == MeshedReservoir.Configuration.idealPressure then
      3E5
    else
      14E5
    "Start value of pressure"
    annotation(Dialog(group="Static pressures"));

  parameter Modelica.Units.SI.PressureDifference dpJun_nominal = 1000
    "Design pressure drop of one leg of a junction";

  parameter Modelica.Units.SI.Mass mTot_start = 3*2065.16
    "Total mass of all expansion vessels at start of simulation. Added manually due to conditionally removed components";

  parameter Modelica.Units.SI.MassFlowRate m_flow_nominal = 685
    "Design mass flow rate";


  parameter MeshedReservoir.Configuration configuration =
    if conInd == 1 then
      MeshedReservoir.Configuration.highPressure
    elseif conInd == 2 then
      MeshedReservoir.Configuration.idealPressure
    else
      MeshedReservoir.Configuration.lowPressure
    "Configuration of all loops";

  parameter Real pumSch_2[:,:]=[
    0.0*3600, 0;
    0.5*3600, 0;
    1.0*3600, m_flow_nominal;
    2.0*3600, m_flow_nominal;
    2.5*3600, 0;
    3.5*3600, 0;
    4.0*3600, m_flow_nominal;
    5.0*3600, m_flow_nominal;
    5.5*3600, 0;
    6.0*3600, 0]
    "Control schedule";

  parameter Real pumSch_13[:,:]=[
    0.0*3600, 0;
    0.5*3600, 0;
    1.0*3600, m_flow_nominal;
    5.0*3600, m_flow_nominal;
    5.5*3600, 0;
    6.0*3600, 0]
    "Control schedule";

  parameter Real pumSch_on[:,:]=[
     0.0*3600, m_flow_nominal]
    "Control schedule";

  parameter Modelica.Units.SI.HeatFlowRate QWasHea_nominal=12E6
    "Gain for waste (or excess) heat flow rate transfer";


  SingleLoop loo1(
    final pMax=pMax,
    final pMin=pMin,
    final p_start=p_start,
    m_flow_nominal=m_flow_nominal,
    dpJun_nominal=dpJun_nominal,
    pumSch=if use_wasteHeat then pumSch_on else pumSch_13,
    isMaster=true,
    mSetAll=mTot_start,
    configuration=configuration,
    QWasHea_nominal=QWasHea_nominal/2)
    "First loop"
    annotation (Placement(transformation(extent={{-24,-62},{12,-40}})));

  SingleLoop loo2(
    final pMax=pMax,
    final pMin=pMin,
    final p_start=p_start,
    m_flow_nominal=m_flow_nominal,
    dpJun_nominal=dpJun_nominal,
    pumSch=if use_wasteHeat then pumSch_on else pumSch_2,
    isMaster=false,
    mSetAll=mTot_start,
    configuration=configuration,
    addHeat=false,
    QWasHea_nominal=QWasHea_nominal)
    "Second loop"
    annotation (Placement(transformation(extent={{-24,0},{12,22}})));

  SingleLoop loo3(
    final pMax=pMax,
    final pMin=pMin,
    final p_start=p_start,
    m_flow_nominal=m_flow_nominal,
    dpJun_nominal=dpJun_nominal,
    pumSch=if use_wasteHeat then pumSch_on else pumSch_13,
    isMaster=false,
    mSetAll=mTot_start,
    configuration=configuration,
    QWasHea_nominal=QWasHea_nominal/2)
    "Third loop"
    annotation (Placement(transformation(extent={{-24,62},{12,84}})));

  Buildings.Controls.OBC.CDL.Reals.MultiSum mTotOth(nin=3)
    "Total mass of all expansion vessels"
    annotation (Placement(transformation(extent={{60,-60},{80,-40}})));
  Buildings.Controls.OBC.CDL.Reals.MultiMax pSysMax(nin=3)
    "Maximum pressure in the system"
    annotation (Placement(transformation(extent={{60,0},{80,20}})));
  Buildings.Controls.OBC.CDL.Reals.MultiMin pSysMin(nin=3)
    "Minimum pressure in the system"
    annotation (Placement(transformation(extent={{60,30},{80,50}})));
  Buildings.Controls.OBC.CDL.Integers.Sources.TimeTable schWasGen(
    table=[0,0; 54,1; 58,0],
    timeScale=3600,
    period=60*24*3600) "Schedule for waste heat generation"
    annotation (Placement(transformation(extent={{-160,30},{-140,50}})));
  Buildings.Controls.OBC.CDL.Integers.Sources.Constant intZer(k=0)
    "Output integer 0"
    annotation (Placement(transformation(extent={{-160,-46},{-140,-26}})));
  Buildings.Controls.OBC.CDL.Integers.Switch intSwiWasGen
    "Switch for waste heat generation"
    annotation (Placement(transformation(extent={{-120,-6},{-100,14}})));
  Buildings.Controls.OBC.CDL.Logical.Sources.Constant swiWasHea(k=use_wasteHeat)
    "Switch for enabling waste heat transfer"
    annotation (Placement(transformation(extent={{-160,-6},{-140,14}})));
  Connection con12(
    m_flow_nominal=m_flow_nominal,
    dpJun_nominal=dpJun_nominal) "Connection between loop 1 and 2"
    annotation (Placement(transformation(extent={{-16,-30},{4,-10}})));
  Connection con23(
    m_flow_nominal=m_flow_nominal,
    dpJun_nominal=dpJun_nominal) "Connection between loop 2 and 4"
    annotation (Placement(transformation(extent={{-16,32},{4,52}})));
  Buildings.Controls.OBC.CDL.Integers.Sources.TimeTable schWasUse(
    table=[0,0; 55,-1; 59,0],
    timeScale=3600,
    period=60*24*3600) "Schedule for waste heat use"
    annotation (Placement(transformation(extent={{-160,60},{-140,80}})));
  Buildings.Controls.OBC.CDL.Integers.Switch intSwiWasUse
    "Switch for waste heat use"
    annotation (Placement(transformation(extent={{-120,30},{-100,50}})));
equation
  connect(loo1.m, mTotOth.u[1]) annotation (Line(points={{13,-46},{28,-46},{28,
          -50.6667},{58,-50.6667}},
                          color={0,0,127}));
  connect(loo2.m, mTotOth.u[2]) annotation (Line(points={{13,16},{28,16},{28,-42},
          {30,-42},{30,-50},{58,-50}}, color={0,0,127}));
  connect(loo3.m, mTotOth.u[3]) annotation (Line(points={{13,78},{28,78},{28,
          -49.3333},{58,-49.3333}},
                          color={0,0,127}));
  connect(mTotOth.y, loo3.mAll) annotation (Line(points={{82,-50},{90,-50},{90,-80},
          {-50,-80},{-50,72},{-26,72}}, color={0,0,127}));
  connect(mTotOth.y, loo2.mAll) annotation (Line(points={{82,-50},{90,-50},{90,-80},
          {-50,-80},{-50,10},{-26,10}},   color={0,0,127}));
  connect(mTotOth.y, loo1.mAll) annotation (Line(points={{82,-50},{90,-50},{90,-80},
          {-50,-80},{-50,-52},{-26,-52}}, color={0,0,127}));
  connect(loo3.pIn, pSysMin.u[1]) annotation (Line(points={{13,83},{50,83},{50,
          39.3333},{58,39.3333}},    color={0,0,127}));
  connect(loo2.pIn, pSysMin.u[2]) annotation (Line(points={{13,21},{40,21},{40,40},
          {58,40}},        color={0,0,127}));
  connect(loo1.pIn, pSysMin.u[3]) annotation (Line(points={{13,-41},{42,-41},{
          42,40.6667},{58,40.6667}},  color={0,0,127}));
  connect(loo3.pOut, pSysMax.u[1]) annotation (Line(points={{13,81},{46,81},{46,
          9.33333},{58,9.33333}},     color={0,0,127}));
  connect(loo2.pOut, pSysMax.u[2]) annotation (Line(points={{13,19},{46,19},{46,
          10},{58,10}},     color={0,0,127}));
  connect(loo1.pOut, pSysMax.u[3]) annotation (Line(points={{13,-43},{48,-43},{
          48,10.6667},{58,10.6667}},  color={0,0,127}));
  connect(swiWasHea.y, intSwiWasGen.u2)
    annotation (Line(points={{-138,4},{-122,4}}, color={255,0,255}));
  connect(schWasGen.y[1], intSwiWasGen.u1) annotation (Line(points={{-138,40},{
          -134,40},{-134,12},{-122,12}}, color={255,127,0}));
  connect(intZer.y, intSwiWasGen.u3) annotation (Line(points={{-138,-36},{-130,
          -36},{-130,-4},{-122,-4}}, color={255,127,0}));
  connect(intSwiWasGen.y, loo2.ySetWasHea)
    annotation (Line(points={{-98,4},{-26,4}}, color={255,127,0}));
  connect(con12.port_4, loo1.port_1)
    annotation (Line(points={{-8,-30},{-8,-40}}, color={0,127,255}));
  connect(con12.port_3, loo1.port_2)
    annotation (Line(points={{-4,-30},{-4,-40}}, color={0,127,255}));
  connect(loo2.port_4, con12.port_1)
    annotation (Line(points={{-8,0},{-8,-10}}, color={0,127,255}));
  connect(loo2.port_3, con12.port_2)
    annotation (Line(points={{-4,0},{-4,-10}}, color={0,127,255}));
  connect(con23.port_4, loo2.port_1)
    annotation (Line(points={{-8,32},{-8,22}}, color={0,127,255}));
  connect(con23.port_3, loo2.port_2)
    annotation (Line(points={{-4,32},{-4,22}}, color={0,127,255}));
  connect(loo3.port_4, con23.port_1)
    annotation (Line(points={{-8,62},{-8,52}}, color={0,127,255}));
  connect(loo3.port_3, con23.port_2)
    annotation (Line(points={{-4,62},{-4,52}}, color={0,127,255}));
  connect(intZer.y, intSwiWasUse.u3) annotation (Line(points={{-138,-36},{-130,
          -36},{-130,32},{-122,32}}, color={255,127,0}));
  connect(schWasUse.y[1], intSwiWasUse.u1) annotation (Line(points={{-138,70},{
          -130,70},{-130,48},{-122,48}}, color={255,127,0}));
  connect(intSwiWasUse.y, loo3.ySetWasHea) annotation (Line(points={{-98,40},{
          -80,40},{-80,66},{-26,66}}, color={255,127,0}));
  connect(intSwiWasUse.y, loo1.ySetWasHea) annotation (Line(points={{-98,40},{
          -80,40},{-80,-58},{-26,-58}}, color={255,127,0}));
  connect(swiWasHea.y, intSwiWasUse.u2) annotation (Line(points={{-138,4},{-126,
          4},{-126,40},{-122,40}}, color={255,0,255}));
  connect(intSwiWasUse.y, con23.ySetWasHea) annotation (Line(points={{-98,40},{
          -60,40},{-60,42},{-17,42}}, color={255,127,0}));
  connect(intSwiWasUse.y, con12.ySetWasHea) annotation (Line(points={{-98,40},{
          -60,40},{-60,-20},{-17,-20}}, color={255,127,0}));
  annotation (experiment(
      StopTime=216000,
      Tolerance=1e-06,
      __Dymola_Algorithm="Cvode"),
    __Dymola_Commands(file="modelica://MeshedReservoir/Resources/Scripts/Dymola/Examples/ThreeLoops.mos"
        "Simulate and plot"),
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}})),
    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-180,-100},{100,
            100}})));
end ThreeLoops;
