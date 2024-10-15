table 308 "No. Series"
{
    Caption = 'No. Series';
    DataCaptionFields = "Code", Description;
    DrillDownPageID = "No. Series List";
    LookupPageID = "No. Series List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Default Nos."; Boolean)
        {
            Caption = 'Default Nos.';

            trigger OnValidate()
            begin
                if ("Default Nos." = false) and (xRec."Default Nos." <> "Default Nos.") and ("Manual Nos." = false) then
                    Validate("Manual Nos.", true);
            end;
        }
        field(4; "Manual Nos."; Boolean)
        {
            Caption = 'Manual Nos.';

            trigger OnValidate()
            begin
                if ("Manual Nos." = false) and (xRec."Manual Nos." <> "Manual Nos.") and ("Default Nos." = false) then
                    Validate("Default Nos.", true);
            end;
        }
        field(5; "Date Order"; Boolean)
        {
            Caption = 'Date Order';

            trigger OnValidate()
            var
                NoSeriesLine: Record "No. Series Line";
            begin
                if not "Date Order" then
                    exit;
                FindNoSeriesLineToShow(NoSeriesLine);
                if not NoSeriesLine.FindFirst() then
                    exit;
                if NoSeriesLine."Allow Gaps in Nos." then
                    Error(AllowGapsNotAllowedWithDateOrderErr);
            end;
        }
        field(12100; "No. Series Type"; Option)
        {
            Caption = 'No. Series Type';
            OptionCaption = 'Normal,Sales,Purchase';
            OptionMembers = Normal,Sales,Purchase;

            trigger OnValidate()
            begin
                if "No. Series Type" <> xRec."No. Series Type" then begin
                    case xRec."No. Series Type" of
                        "No. Series Type"::Normal:
                            begin
                                NoSeriesLine.SetRange("Series Code", Code);
                                RecordsFound := NoSeriesLine.Find('-');
                            end;
                        "No. Series Type"::Sales:
                            begin
                                NoSeriesLineSales.SetRange("Series Code", Code);
                                RecordsFound := NoSeriesLineSales.Find('-');
                            end;
                        "No. Series Type"::Purchase:
                            begin
                                NoSeriesLinePurchase.SetRange("Series Code", Code);
                                RecordsFound := NoSeriesLinePurchase.Find('-');
                            end;
                    end;

                    if RecordsFound then
                        Error(Text1130004, FieldCaption("No. Series Type"));
                end;
            end;
        }
        field(12101; "VAT Register"; Code[10])
        {
            Caption = 'VAT Register';
            TableRelation = IF ("No. Series Type" = CONST(Sales)) "VAT Register" WHERE(Type = CONST(Sale))
            ELSE
            IF ("No. Series Type" = CONST(Purchase)) "VAT Register" WHERE(Type = CONST(Purchase));

            trigger OnValidate()
            begin
                if "No. Series Type" = "No. Series Type"::Normal then
                    Error(Text1130000, FieldCaption("No. Series Type"));
            end;
        }
        field(12102; "VAT Reg. Print Priority"; Integer)
        {
            Caption = 'VAT Reg. Print Priority';
        }
        field(12103; "Reverse Sales VAT No. Series"; Code[20])
        {
            Caption = 'Reverse Sales VAT No. Series';
            TableRelation = IF ("No. Series Type" = CONST(Sales)) "No. Series" WHERE("No. Series Type" = CONST(Purchase))
            ELSE
            IF ("No. Series Type" = CONST(Purchase)) "No. Series" WHERE("No. Series Type" = CONST(Sales));

            trigger OnValidate()
            begin
                if "No. Series Type" = "No. Series Type"::Normal then
                    Error(Text1130000, FieldCaption("No. Series Type"));
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "VAT Reg. Print Priority")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description)
        {
        }
    }

    trigger OnDelete()
    begin
        NoSeriesLine.SetRange("Series Code", Code);
        NoSeriesLine.DeleteAll();

        NoSeriesLineSales.SetRange("Series Code", Code);
        NoSeriesLineSales.DeleteAll();

        NoSeriesLinePurchase.SetRange("Series Code", Code);
        NoSeriesLinePurchase.DeleteAll();

        NoSeriesRelationship.SetRange(Code, Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange(Code);

        NoSeriesRelationship.SetRange("Series Code", Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange("Series Code");
    end;

    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesRelationship: Record "No. Series Relationship";
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
        RecordsFound: Boolean;
        AllowGapsNotAllowedWithDateOrderErr: Label 'The Date Order setting is not possible for this number series because the Allow Gaps in Nos. check box is selected on one of the number series lines.';
        Text1130000: Label '%1 must not be Normal';
        Text1130004: Label 'No. Serie Lines must be deleted before changing the %1';

    procedure DrillDown()
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        case "No. Series Type" of
            "No. Series Type"::Normal:
                begin
                    FindNoSeriesLineToShow(NoSeriesLine);
                    if NoSeriesLine.Find('-') then;
                    NoSeriesLine.SetRange("Starting Date");
                    NoSeriesLine.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLine);
                end;
            "No. Series Type"::Sales:
                begin
                    FindNoSeriesLineSalesToShow(NoSeriesLineSales);
                    if NoSeriesLineSales.Find('-') then;
                    NoSeriesLineSales.SetRange("Starting Date");
                    NoSeriesLineSales.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLineSales);
                end;
            "No. Series Type"::Purchase:
                begin
                    FindNoSeriesLinePurchToShow(NoSeriesLinePurchase);
                    if NoSeriesLinePurchase.Find('-') then;
                    NoSeriesLinePurchase.SetRange("Starting Date");
                    NoSeriesLinePurchase.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLinePurchase);
                end;
        end;
    end;

    procedure UpdateLine(var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date)
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
    begin
        case "No. Series Type" of
            "No. Series Type"::Normal:
                begin
                    FindNoSeriesLineToShow(NoSeriesLine);
                    if not NoSeriesLine.Find('-') then
                        NoSeriesLine.Init();
                    StartDate := NoSeriesLine."Starting Date";
                    StartNo := NoSeriesLine."Starting No.";
                    EndNo := NoSeriesLine."Ending No.";
                    LastNoUsed := NoSeriesLine.GetLastNoUsed;
                    WarningNo := NoSeriesLine."Warning No.";
                    IncrementByNo := NoSeriesLine."Increment-by No.";
                    LastDateUsed := NoSeriesLine."Last Date Used";
                end;
            "No. Series Type"::Sales:
                begin
                    FindNoSeriesLineSalesToShow(NoSeriesLineSales);
                    if not NoSeriesLineSales.Find('-') then
                        NoSeriesLineSales.Init();
                    StartDate := NoSeriesLineSales."Starting Date";
                    StartNo := NoSeriesLineSales."Starting No.";
                    EndNo := NoSeriesLineSales."Ending No.";
                    LastNoUsed := NoSeriesLineSales."Last No. Used";
                    WarningNo := NoSeriesLineSales."Warning No.";
                    IncrementByNo := NoSeriesLineSales."Increment-by No.";
                    LastDateUsed := NoSeriesLineSales."Last Date Used"
                end;
            "No. Series Type"::Purchase:
                begin
                    FindNoSeriesLinePurchToShow(NoSeriesLinePurchase);
                    if not NoSeriesLinePurchase.Find('-') then
                        NoSeriesLinePurchase.Init();
                    StartDate := NoSeriesLinePurchase."Starting Date";
                    StartNo := NoSeriesLinePurchase."Starting No.";
                    EndNo := NoSeriesLinePurchase."Ending No.";
                    LastNoUsed := NoSeriesLinePurchase."Last No. Used";
                    WarningNo := NoSeriesLinePurchase."Warning No.";
                    IncrementByNo := NoSeriesLinePurchase."Increment-by No.";
                    LastDateUsed := NoSeriesLinePurchase."Last Date Used"
                end;
        end;
    end;

    local procedure FindNoSeriesLineToShow(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        NoSeriesMgt.SetNoSeriesLineFilter(NoSeriesLine, Code, 0D);

        if NoSeriesLine.FindLast() then
            exit;

        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", Code);
    end;

    local procedure FindNoSeriesLineSalesToShow(var NoSeriesLineSales: Record "No. Series Line Sales")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        NoSeriesMgt.SetNoSeriesLineSalesFilter(NoSeriesLineSales, Code, 0D);

        if NoSeriesLineSales.FindLast() then
            exit;

        NoSeriesLineSales.Reset();
        NoSeriesLineSales.SetRange("Series Code", Code);
    end;

    local procedure FindNoSeriesLinePurchToShow(var NoSeriesLinePurchase: Record "No. Series Line Purchase")
    var
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        NoSeriesMgt.SetNoSeriesLinePurchaseFilter(NoSeriesLinePurchase, Code, 0D);

        if NoSeriesLinePurchase.FindLast() then
            exit;

        NoSeriesLinePurchase.Reset();
        NoSeriesLinePurchase.SetRange("Series Code", Code);
    end;
}

