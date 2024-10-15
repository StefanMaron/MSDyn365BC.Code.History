table 31065 "Stat. Reporting Setup"
{
    Caption = 'Stat. Reporting Setup';
#if CLEAN18
    ObsoleteState = Removed;
#else
    ObsoleteState = Pending;
#endif
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(27; "Tax Office Number"; Code[20])
        {
            Caption = 'Tax Office Number';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(40; "Municipality No."; Text[30])
        {
            Caption = 'Municipality No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(41; Street; Text[50])
        {
            Caption = 'Street';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(42; "House No."; Text[30])
        {
            Caption = 'House No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(43; "Apartment No."; Text[30])
        {
            Caption = 'Apartment No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(51; "VIES Decl. Auth. Employee No."; Code[20])
        {
            Caption = 'VIES Decl. Auth. Employee No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            TableRelation = "Company Officials";
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(52; "VIES Decl. Filled by Empl. No."; Code[20])
        {
            Caption = 'VIES Decl. Filled by Empl. No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            TableRelation = "Company Officials";
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(54; "VIES Decl. Exp. Obj. Type"; Option)
        {
            Caption = 'VIES Decl. Exp. Obj. Type';
            OptionCaption = ',,,Report,,Codeunit';
            OptionMembers = ,,,"Report",,"Codeunit";
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
#if not CLEAN17

            trigger OnValidate()
            begin
                if xRec."VIES Decl. Exp. Obj. Type" <> "VIES Decl. Exp. Obj. Type" then
                    Validate("VIES Decl. Exp. Obj. No.", 0);
            end;
#endif
        }
        field(55; "VIES Declaration Nos."; Code[20])
        {
            Caption = 'VIES Declaration Nos.';
            TableRelation = "No. Series";
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(56; "VIES Declaration Report No."; Integer)
        {
            Caption = 'VIES Declaration Report No.';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Report));
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
#if not CLEAN17

            trigger OnValidate()
            begin
                CalcFields("VIES Declaration Report Name");
            end;
#endif
        }
#if not CLEAN17
        field(57; "VIES Declaration Report Name"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("VIES Declaration Report No.")));
            Caption = 'VIES Declaration Report Name';
            Editable = false;
            FieldClass = FlowField;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
#endif
        field(58; "VIES Decl. Exp. Obj. No."; Integer)
        {
            Caption = 'VIES Decl. Exp. Obj. No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            TableRelation = AllObj."Object ID" WHERE("Object Type" = FIELD("VIES Decl. Exp. Obj. Type"));
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
#if not CLEAN17

            trigger OnLookup()
            var
                AllObjWithCaption: Record AllObjWithCaption;
                PageObjects: Page Objects;
            begin
                if AllObjWithCaption.Get("VIES Decl. Exp. Obj. Type", "VIES Decl. Exp. Obj. No.") then
                    PageObjects.SetRecord(AllObjWithCaption);
                AllObjWithCaption.FilterGroup(2);
                AllObjWithCaption.SetRange("Object Type", "VIES Decl. Exp. Obj. Type");
                PageObjects.SetTableView(AllObjWithCaption);
                PageObjects.LookupMode(true);
                if PageObjects.RunModal = ACTION::LookupOK then begin
                    PageObjects.GetRecord(AllObjWithCaption);
                    Validate("VIES Decl. Exp. Obj. No.", AllObjWithCaption."Object ID");
                end else
                    Error('');
            end;

            trigger OnValidate()
            begin
                CalcFields("VIES Decl. Exp. Obj. Name");
            end;
#endif
        }
#if not CLEAN17
        field(59; "VIES Decl. Exp. Obj. Name"; Text[250])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = FIELD("VIES Decl. Exp. Obj. Type"),
                                                                           "Object ID" = FIELD("VIES Decl. Exp. Obj. No.")));
            Caption = 'VIES Decl. Exp. Obj. Name';
            Editable = false;
            FieldClass = FlowField;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
#endif
        field(60; "Transaction Type Mandatory"; Boolean)
        {
            Caption = 'Transaction Type Mandatory';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(61; "Transaction Spec. Mandatory"; Boolean)
        {
            Caption = 'Transaction Spec. Mandatory';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(62; "Transport Method Mandatory"; Boolean)
        {
            Caption = 'Transport Method Mandatory';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(63; "Shipment Method Mandatory"; Boolean)
        {
            Caption = 'Shipment Method Mandatory';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(64; "Tariff No. Mandatory"; Boolean)
        {
            Caption = 'Tariff No. Mandatory';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(65; "Net Weight Mandatory"; Boolean)
        {
            Caption = 'Net Weight Mandatory';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(66; "Country/Region of Origin Mand."; Boolean)
        {
            Caption = 'Country/Region of Origin Mand.';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(67; "Get Tariff No. From"; Option)
        {
            Caption = 'Get Tariff No. From';
            OptionCaption = 'Posted Entries,Item Card';
            OptionMembers = "Posted Entries","Item Card";
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(68; "Get Net Weight From"; Option)
        {
            Caption = 'Get Net Weight From';
            OptionCaption = 'Posted Entries,Item Card';
            OptionMembers = "Posted Entries","Item Card";
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(69; "Get Country/Region of Origin"; Option)
        {
            Caption = 'Get Country/Region of Origin';
            OptionCaption = 'Posted Entries,Item Card';
            OptionMembers = "Posted Entries","Item Card";
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(70; "Intrastat Rounding Type"; Option)
        {
            Caption = 'Intrastat Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(71; "No Item Charges in Intrastat"; Boolean)
        {
            Caption = 'No Item Charges in Intrastat';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
#if not CLEAN18

            trigger OnValidate()
            begin
                ItemCharge.Reset();
                ItemCharge.SetRange("Incl. in Intrastat Amount", true);
                if ItemCharge.FindFirst then
                    Error(Text26500Err,
                      FieldCaption("No Item Charges in Intrastat"),
                      ItemCharge.TableCaption, ItemCharge.FieldCaption("Incl. in Intrastat Amount"));

                ItemCharge.Reset();
                ItemCharge.SetRange("Incl. in Intrastat Stat. Value", true);
                if ItemCharge.FindFirst then
                    Error(Text26500Err,
                      FieldCaption("No Item Charges in Intrastat"),
                      ItemCharge.TableCaption, ItemCharge.FieldCaption("Incl. in Intrastat Stat. Value"));
            end;
#endif
        }
        field(11700; "Natural Person First Name"; Text[30])
        {
            Caption = 'Natural Person First Name';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11701; "Natural Person Surname"; Text[30])
        {
            Caption = 'Natural Person Surname';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11702; "Natural Person Title"; Text[30])
        {
            Caption = 'Natural Person Title';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11703; "Taxpayer Type"; Option)
        {
            Caption = 'Taxpayer Type';
            OptionCaption = 'Corporation,Individual';
            OptionMembers = Corporation,Individual;
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Core Localization Pack for Czech field Company Type.';
            ObsoleteTag = '17.5';
        }
        field(11704; "Company Trade Name Appendix"; Text[11])
        {
            Caption = 'Company Trade Name Appendix';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11705; "Natural Employee No."; Code[20])
        {
            Caption = 'Natural Employee No.';
            TableRelation = Employee;
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11708; "Tax Payer Status"; Option)
        {
            Caption = 'Tax Payer Status';
            OptionCaption = 'Payer,Non-payer,Other,VAT Group';
            OptionMembers = Payer,"Non-payer",Other,"VAT Group";
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11709; "Area Code"; Code[10])
        {
            Caption = 'Area Code';
            TableRelation = Area;
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11710; "Main Economic Activity I Code"; Code[10])
        {
            Caption = 'Main Economic Activity I Code';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11711; "Main Economic Activity I Desc."; Text[50])
        {
            Caption = 'Main Economic Activity I Desc.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11712; "Main Economic Activity II Code"; Code[10])
        {
            Caption = 'Main Economic Activity II Code';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11713; "Main Economic Activity II Desc"; Text[50])
        {
            Caption = 'Main Economic Activity II Desc';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11714; "Company Trade Name"; Text[100])
        {
            Caption = 'Company Trade Name';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11715; "Organizational Unit Code"; Integer)
        {
            Caption = 'Organizational Unit Code';
            MaxValue = 95;
            MinValue = 1;
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11716; "Customs Office No."; Code[20])
        {
            Caption = 'Customs Office No.';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Unsupported functionality';
            ObsoleteTag = '18.0';
        }
        field(11717; "Customs Office Name"; Text[30])
        {
            Caption = 'Customs Office Name';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Unsupported functionality';
            ObsoleteTag = '18.0';
        }
        field(11718; "Intrastat Declaration Nos."; Code[20])
        {
            Caption = 'Intrastat Declaration Nos.';
            TableRelation = "No. Series";
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(11725; "VIES Number of Lines"; Integer)
        {
            Caption = 'VIES Number of Lines';
            MaxValue = 27;
            MinValue = 0;
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11726; "VAT Statement Country Name"; Text[25])
        {
            Caption = 'VAT Statement Country Name';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11753; "VAT Stat. Auth.Employee No."; Code[20])
        {
            Caption = 'VAT Stat. Auth.Employee No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            TableRelation = "Company Officials";
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11754; "VAT Stat. Filled by Empl. No."; Code[20])
        {
            Caption = 'VAT Stat. Filled by Empl. No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            TableRelation = "Company Officials";
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(11760; "Authorized Person First Name"; Text[50])
        {
            Caption = 'Authorized Person First Name';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11761; "Authorized Person Title"; Text[50])
        {
            Caption = 'Authorized Person Title';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11762; "Authorized Person Phone No."; Text[20])
        {
            Caption = 'Authorized Person Phone No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11763; "Authorized Person Surname"; Text[50])
        {
            Caption = 'Authorized Person Surname';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11764; "Filled by Person First Name"; Text[50])
        {
            Caption = 'Filled by Person First Name';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11765; "Filled by Person Title"; Text[50])
        {
            Caption = 'Filled by Person Title';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11766; "Filled by Person Phone No."; Text[20])
        {
            Caption = 'Filled by Person Phone No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(11767; "Filled by Person Surname"; Text[50])
        {
            Caption = 'Filled by Person Surname';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This unused field is discontinued and will be removed.';
            ObsoleteTag = '17.0';
        }
        field(31060; "Include other Period add.Costs"; Boolean)
        {
            Caption = 'Include other Period add.Costs';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
        }
        field(31061; "Intrastat Export Object Type"; Option)
        {
            BlankZero = true;
            Caption = 'Intrastat Export Object Type';
            InitValue = "Report";
            OptionCaption = ',,,Report,,Codeunit,XMLPort';
            OptionMembers = ,,,"Report",,"Codeunit","XMLPort";
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This field is discontinued. Use Intrastat Jnl. Line event OnBeforeExportIntrastatJournalCZL to change export means.';
            ObsoleteTag = '18.0';
#if not CLEAN18

            trigger OnValidate()
            begin
                if "Intrastat Export Object Type" <> xRec."Intrastat Export Object Type" then
                    "Intrastat Export Object No." := 0;
            end;
#endif
        }
        field(31062; "Intrastat Export Object No."; Integer)
        {
            BlankZero = true;
            Caption = 'Intrastat Export Object No.';
#if CLEAN18
            ObsoleteState = Removed;
#else
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = FIELD("Intrastat Export Object Type"));
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'This field is discontinued. Use Intrastat Jnl. Line event OnBeforeExportIntrastatJournalCZL to change export means.';
            ObsoleteTag = '18.0';
#if not CLEAN18

            trigger OnLookup()
            var
                AllObjWithCaption: Record AllObjWithCaption;
                PageObjects: Page Objects;
            begin
                if AllObjWithCaption.Get("Intrastat Export Object Type", "Intrastat Export Object No.") then
                    PageObjects.SetRecord(AllObjWithCaption);
                AllObjWithCaption.FilterGroup(2);
                AllObjWithCaption.SetRange("Object Type", "Intrastat Export Object Type");
                PageObjects.SetTableView(AllObjWithCaption);
                PageObjects.LookupMode(true);
                if PageObjects.RunModal = ACTION::LookupOK then begin
                    PageObjects.GetRecord(AllObjWithCaption);
                    "Intrastat Export Object No." := AllObjWithCaption."Object ID";
                end else
                    Error('');
            end;
#endif
        }
        field(31063; "Intrastat Exch.Rate Mandatory"; Boolean)
        {
            Caption = 'Intrastat Exch.Rate Mandatory';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Unsupported functionality';
            ObsoleteTag = '18.0';
        }
        field(31064; "Tax Office Region Number"; Code[20])
        {
            Caption = 'Tax Office Region Number';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31065; "Stat. Value Reporting"; Option)
        {
            Caption = 'Stat. Value Reporting';
            OptionCaption = 'None,Percentage,Shipment Method';
            OptionMembers = "None",Percentage,"Shipment Method";
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
#if not CLEAN18

            trigger OnValidate()
            begin
                if "Stat. Value Reporting" <> xRec."Stat. Value Reporting" then
                    Clear("Cost Regulation %");
            end;
#endif
        }
        field(31066; "Cost Regulation %"; Decimal)
        {
            Caption = 'Cost Regulation %';
            MinValue = 0;
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '18.0';
#if not CLEAN18

            trigger OnValidate()
            begin
                if "Cost Regulation %" <> 0 then
                    TestField("Stat. Value Reporting", "Stat. Value Reporting"::Percentage);
            end;
#endif
        }
        field(31067; "Ignore Intrastat Ex.Rate From"; Date)
        {
            Caption = 'Ignore Intrastat Ex.Rate From';
#if CLEAN18
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Unsupported functionality';
            ObsoleteTag = '18.0';
        }
        field(31090; "Reverse Charge Nos."; Code[20])
        {
            Caption = 'Reverse Charge Nos.';
            TableRelation = "No. Series";
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Reverse Charge Statement will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31095; "Reverse Charge Auth. Emp. No."; Code[20])
        {
            Caption = 'Reverse Charge Auth. Emp. No.';
#if not CLEAN17
            TableRelation = "Company Officials";
#endif
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Reverse Charge Statement will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31096; "Rvrs. Chrg. Filled by Emp. No."; Code[20])
        {
            Caption = 'Reverse Charge Filled by Emp. No.';
#if not CLEAN17
            TableRelation = "Company Officials";
#endif
            ObsoleteState = Removed;
            ObsoleteReason = 'The functionality of Reverse Charge Statement will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '18.0';
        }
        field(31100; "VAT Control Report Nos."; Code[20])
        {
            Caption = 'VAT Control Report Nos.';
            TableRelation = "No. Series";
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31101; "Simplified Tax Document Limit"; Decimal)
        {
            Caption = 'Simplified Tax Document Limit';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31102; "Data Box ID"; Text[20])
        {
            Caption = 'Data Box ID';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31103; "VAT Control Report E-mail"; Text[80])
        {
            Caption = 'VAT Control Report E-mail';
            ExtendedDatatype = EMail;
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
#if not CLEAN17

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("VAT Control Report E-mail");
            end;
#endif
        }
        field(31104; "VAT Control Report Xml Format"; Option)
        {
            Caption = 'VAT Control Report Xml Format';
            OptionCaption = 'KH 02.01.03,KH 03.01.01';
            OptionMembers = "KH 02.01.03","KH 03.01.01";
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31105; "Official Code"; Text[2])
        {
            Caption = 'Official Code';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31106; "Official Type"; Option)
        {
            Caption = 'Official Type';
            OptionCaption = ' ,Individual,Corporate';
            OptionMembers = " ",Individual,Corporate;
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31107; "Official Name"; Text[30])
        {
            Caption = 'Official Name';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31108; "Official First Name"; Text[30])
        {
            Caption = 'Official First Name';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31109; "Official Surname"; Text[30])
        {
            Caption = 'Official Surname';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31110; "Official Birth Date"; Date)
        {
            Caption = 'Official Birth Date';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31111; "Official Reg.No.of Tax Adviser"; Text[36])
        {
            Caption = 'Official Reg.No.of Tax Adviser';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
        field(31112; "Official Registration No."; Text[20])
        {
            Caption = 'Official Registration No.';
#if CLEAN17
            ObsoleteState = Removed;
#else
            ObsoleteState = Pending;
#endif
            ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
            ObsoleteTag = '17.0';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ItemCharge: Record "Item Charge";
        Text26500Err: Label 'You cannot uncheck %1 until you have %2 with checked field %3.', Comment = '%1=fieldcaption.NoItemChargesinIntrastat;%2=itemcharge.tablecaption;%3=fieldcaption';
}

