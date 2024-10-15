table 31065 "Stat. Reporting Setup"
{
    Caption = 'Stat. Reporting Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(27; "Tax Office Number"; Code[20])
        {
            Caption = 'Tax Office Number';
        }
        field(40; "Municipality No."; Text[30])
        {
            Caption = 'Municipality No.';
        }
        field(41; Street; Text[50])
        {
            Caption = 'Street';
        }
        field(42; "House No."; Text[30])
        {
            Caption = 'House No.';
        }
        field(43; "Apartment No."; Text[30])
        {
            Caption = 'Apartment No.';
        }
        field(51; "VIES Decl. Auth. Employee No."; Code[20])
        {
            Caption = 'VIES Decl. Auth. Employee No.';
            TableRelation = "Company Officials";
        }
        field(52; "VIES Decl. Filled by Empl. No."; Code[20])
        {
            Caption = 'VIES Decl. Filled by Empl. No.';
            TableRelation = "Company Officials";
        }
        field(54; "VIES Decl. Exp. Obj. Type"; Option)
        {
            Caption = 'VIES Decl. Exp. Obj. Type';
            OptionCaption = ',,,Report,,Codeunit';
            OptionMembers = ,,,"Report",,"Codeunit";

            trigger OnValidate()
            begin
                if xRec."VIES Decl. Exp. Obj. Type" <> "VIES Decl. Exp. Obj. Type" then
                    Validate("VIES Decl. Exp. Obj. No.", 0);
            end;
        }
        field(55; "VIES Declaration Nos."; Code[20])
        {
            Caption = 'VIES Declaration Nos.';
            TableRelation = "No. Series";
        }
        field(56; "VIES Declaration Report No."; Integer)
        {
            Caption = 'VIES Declaration Report No.';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Report));

            trigger OnValidate()
            begin
                CalcFields("VIES Declaration Report Name");
            end;
        }
        field(57; "VIES Declaration Report Name"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Report),
                                                                           "Object ID" = FIELD("VIES Declaration Report No.")));
            Caption = 'VIES Declaration Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(58; "VIES Decl. Exp. Obj. No."; Integer)
        {
            Caption = 'VIES Decl. Exp. Obj. No.';
            TableRelation = AllObj."Object ID" WHERE("Object Type" = FIELD("VIES Decl. Exp. Obj. Type"));

            trigger OnLookup()
            var
                AllObjWithCaption: Record AllObjWithCaption;
                PageObjects: Page Objects;
            begin
                if AllObjWithCaption.Get("Intrastat Export Object Type", "Intrastat Export Object No.") then
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
        }
        field(59; "VIES Decl. Exp. Obj. Name"; Text[250])
        {
            CalcFormula = Lookup (AllObjWithCaption."Object Caption" WHERE("Object Type" = FIELD("VIES Decl. Exp. Obj. Type"),
                                                                           "Object ID" = FIELD("VIES Decl. Exp. Obj. No.")));
            Caption = 'VIES Decl. Exp. Obj. Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Transaction Type Mandatory"; Boolean)
        {
            Caption = 'Transaction Type Mandatory';
        }
        field(61; "Transaction Spec. Mandatory"; Boolean)
        {
            Caption = 'Transaction Spec. Mandatory';
        }
        field(62; "Transport Method Mandatory"; Boolean)
        {
            Caption = 'Transport Method Mandatory';
        }
        field(63; "Shipment Method Mandatory"; Boolean)
        {
            Caption = 'Shipment Method Mandatory';
        }
        field(64; "Tariff No. Mandatory"; Boolean)
        {
            Caption = 'Tariff No. Mandatory';
        }
        field(65; "Net Weight Mandatory"; Boolean)
        {
            Caption = 'Net Weight Mandatory';
        }
        field(66; "Country/Region of Origin Mand."; Boolean)
        {
            Caption = 'Country/Region of Origin Mand.';
        }
        field(67; "Get Tariff No. From"; Option)
        {
            Caption = 'Get Tariff No. From';
            OptionCaption = 'Posted Entries,Item Card';
            OptionMembers = "Posted Entries","Item Card";
        }
        field(68; "Get Net Weight From"; Option)
        {
            Caption = 'Get Net Weight From';
            OptionCaption = 'Posted Entries,Item Card';
            OptionMembers = "Posted Entries","Item Card";
        }
        field(69; "Get Country/Region of Origin"; Option)
        {
            Caption = 'Get Country/Region of Origin';
            OptionCaption = 'Posted Entries,Item Card';
            OptionMembers = "Posted Entries","Item Card";
        }
        field(70; "Intrastat Rounding Type"; Option)
        {
            Caption = 'Intrastat Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(71; "No Item Charges in Intrastat"; Boolean)
        {
            Caption = 'No Item Charges in Intrastat';

            trigger OnValidate()
            begin
                ItemCharge.Reset;
                ItemCharge.SetRange("Incl. in Intrastat Amount", true);
                if ItemCharge.FindFirst then
                    Error(Text26500Err,
                      FieldCaption("No Item Charges in Intrastat"),
                      ItemCharge.TableCaption, ItemCharge.FieldCaption("Incl. in Intrastat Amount"));

                ItemCharge.Reset;
                ItemCharge.SetRange("Incl. in Intrastat Stat. Value", true);
                if ItemCharge.FindFirst then
                    Error(Text26500Err,
                      FieldCaption("No Item Charges in Intrastat"),
                      ItemCharge.TableCaption, ItemCharge.FieldCaption("Incl. in Intrastat Stat. Value"));
            end;
        }
        field(11700; "Natural Person First Name"; Text[30])
        {
            Caption = 'Natural Person First Name';
        }
        field(11701; "Natural Person Surname"; Text[30])
        {
            Caption = 'Natural Person Surname';
        }
        field(11702; "Natural Person Title"; Text[30])
        {
            Caption = 'Natural Person Title';
        }
        field(11703; "Taxpayer Type"; Option)
        {
            Caption = 'Taxpayer Type';
            OptionCaption = 'Corporation,Individual';
            OptionMembers = Corporation,Individual;
        }
        field(11704; "Company Trade Name Appendix"; Text[11])
        {
            Caption = 'Company Trade Name Appendix';
        }
        field(11705; "Natural Employee No."; Code[20])
        {
            Caption = 'Natural Employee No.';
            TableRelation = Employee;
        }
        field(11708; "Tax Payer Status"; Option)
        {
            Caption = 'Tax Payer Status';
            OptionCaption = 'Payer,Non-payer,Other,VAT Group';
            OptionMembers = Payer,"Non-payer",Other,"VAT Group";
        }
        field(11709; "Area Code"; Code[10])
        {
            Caption = 'Area Code';
            TableRelation = Area;
        }
        field(11710; "Main Economic Activity I Code"; Code[10])
        {
            Caption = 'Main Economic Activity I Code';
        }
        field(11711; "Main Economic Activity I Desc."; Text[50])
        {
            Caption = 'Main Economic Activity I Desc.';
        }
        field(11712; "Main Economic Activity II Code"; Code[10])
        {
            Caption = 'Main Economic Activity II Code';
        }
        field(11713; "Main Economic Activity II Desc"; Text[50])
        {
            Caption = 'Main Economic Activity II Desc';
        }
        field(11714; "Company Trade Name"; Text[100])
        {
            Caption = 'Company Trade Name';
        }
        field(11715; "Organizational Unit Code"; Integer)
        {
            Caption = 'Organizational Unit Code';
            MaxValue = 95;
            MinValue = 1;
        }
        field(11716; "Customs Office No."; Code[20])
        {
            Caption = 'Customs Office No.';
        }
        field(11717; "Customs Office Name"; Text[30])
        {
            Caption = 'Customs Office Name';
        }
        field(11718; "Intrastat Declaration Nos."; Code[20])
        {
            Caption = 'Intrastat Declaration Nos.';
            TableRelation = "No. Series";
        }
        field(11725; "VIES Number of Lines"; Integer)
        {
            Caption = 'VIES Number of Lines';
            MaxValue = 27;
            MinValue = 0;
        }
        field(11726; "VAT Statement Country Name"; Text[25])
        {
            Caption = 'VAT Statement Country Name';
        }
        field(11753; "VAT Stat. Auth.Employee No."; Code[20])
        {
            Caption = 'VAT Stat. Auth.Employee No.';
            TableRelation = "Company Officials";
        }
        field(11754; "VAT Stat. Filled by Empl. No."; Code[20])
        {
            Caption = 'VAT Stat. Filled by Empl. No.';
            TableRelation = "Company Officials";
        }
        field(11760; "Authorized Person First Name"; Text[50])
        {
            Caption = 'Authorized Person First Name';
        }
        field(11761; "Authorized Person Title"; Text[50])
        {
            Caption = 'Authorized Person Title';
        }
        field(11762; "Authorized Person Phone No."; Text[20])
        {
            Caption = 'Authorized Person Phone No.';
        }
        field(11763; "Authorized Person Surname"; Text[50])
        {
            Caption = 'Authorized Person Surname';
        }
        field(11764; "Filled by Person First Name"; Text[50])
        {
            Caption = 'Filled by Person First Name';
        }
        field(11765; "Filled by Person Title"; Text[50])
        {
            Caption = 'Filled by Person Title';
        }
        field(11766; "Filled by Person Phone No."; Text[20])
        {
            Caption = 'Filled by Person Phone No.';
        }
        field(11767; "Filled by Person Surname"; Text[50])
        {
            Caption = 'Filled by Person Surname';
        }
        field(31060; "Include other Period add.Costs"; Boolean)
        {
            Caption = 'Include other Period add.Costs';
        }
        field(31061; "Intrastat Export Object Type"; Option)
        {
            BlankZero = true;
            Caption = 'Intrastat Export Object Type';
            InitValue = "Report";
            OptionCaption = ',,,Report,,Codeunit,XMLPort';
            OptionMembers = ,,,"Report",,"Codeunit","XMLPort";

            trigger OnValidate()
            begin
                if "Intrastat Export Object Type" <> xRec."Intrastat Export Object Type" then
                    "Intrastat Export Object No." := 0;
            end;
        }
        field(31062; "Intrastat Export Object No."; Integer)
        {
            BlankZero = true;
            Caption = 'Intrastat Export Object No.';
            TableRelation = AllObjWithCaption."Object ID" WHERE("Object Type" = FIELD("Intrastat Export Object Type"));

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
        }
        field(31063; "Intrastat Exch.Rate Mandatory"; Boolean)
        {
            Caption = 'Intrastat Exch.Rate Mandatory';
        }
        field(31064; "Tax Office Region Number"; Code[20])
        {
            Caption = 'Tax Office Region Number';
        }
        field(31065; "Stat. Value Reporting"; Option)
        {
            Caption = 'Stat. Value Reporting';
            OptionCaption = 'None,Percentage,Shipment Method';
            OptionMembers = "None",Percentage,"Shipment Method";

            trigger OnValidate()
            begin
                if "Stat. Value Reporting" <> xRec."Stat. Value Reporting" then
                    Clear("Cost Regulation %");
            end;
        }
        field(31066; "Cost Regulation %"; Decimal)
        {
            Caption = 'Cost Regulation %';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Cost Regulation %" <> 0 then
                    TestField("Stat. Value Reporting", "Stat. Value Reporting"::Percentage);
            end;
        }
        field(31067; "Ignore Intrastat Ex.Rate From"; Date)
        {
            Caption = 'Ignore Intrastat Ex.Rate From';
        }
        field(31090; "Reverse Charge Nos."; Code[20])
        {
            Caption = 'Reverse Charge Nos.';
            TableRelation = "No. Series";
        }
        field(31095; "Reverse Charge Auth. Emp. No."; Code[20])
        {
            Caption = 'Reverse Charge Auth. Emp. No.';
            TableRelation = "Company Officials";
        }
        field(31096; "Rvrs. Chrg. Filled by Emp. No."; Code[20])
        {
            Caption = 'Reverse Charge Filled by Emp. No.';
            TableRelation = "Company Officials";
        }
        field(31100; "VAT Control Report Nos."; Code[20])
        {
            Caption = 'VAT Control Report Nos.';
            TableRelation = "No. Series";
        }
        field(31101; "Simplified Tax Document Limit"; Decimal)
        {
            Caption = 'Simplified Tax Document Limit';
        }
        field(31102; "Data Box ID"; Text[20])
        {
            Caption = 'Data Box ID';
        }
        field(31103; "VAT Control Report E-mail"; Text[80])
        {
            Caption = 'VAT Control Report E-mail';
            ExtendedDatatype = EMail;
        }
        field(31104; "VAT Control Report Xml Format"; Option)
        {
            Caption = 'VAT Control Report Xml Format';
            OptionCaption = 'KH 02.01.03,KH 03.01.01';
            OptionMembers = "KH 02.01.03","KH 03.01.01";
        }
        field(31105; "Official Code"; Text[2])
        {
            Caption = 'Official Code';
        }
        field(31106; "Official Type"; Option)
        {
            Caption = 'Official Type';
            OptionCaption = ' ,Individual,Corporate';
            OptionMembers = " ",Individual,Corporate;
        }
        field(31107; "Official Name"; Text[30])
        {
            Caption = 'Official Name';
        }
        field(31108; "Official First Name"; Text[30])
        {
            Caption = 'Official First Name';
        }
        field(31109; "Official Surname"; Text[30])
        {
            Caption = 'Official Surname';
        }
        field(31110; "Official Birth Date"; Date)
        {
            Caption = 'Official Birth Date';
        }
        field(31111; "Official Reg.No.of Tax Adviser"; Text[36])
        {
            Caption = 'Official Reg.No.of Tax Adviser';
        }
        field(31112; "Official Registration No."; Text[20])
        {
            Caption = 'Official Registration No.';
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

