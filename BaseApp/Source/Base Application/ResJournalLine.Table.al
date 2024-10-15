table 207 "Res. Journal Line"
{
    Caption = 'Res. Journal Line';

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Res. Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Usage,Sale';
            OptionMembers = Usage,Sale;
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';

            trigger OnValidate()
            begin
                TestField("Posting Date");
                Validate("Document Date", "Posting Date");
            end;
        }
        field(6; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;

            trigger OnValidate()
            begin
                if "Resource No." = '' then begin
                    CreateDim(
                      DATABASE::Resource, "Resource No.",
                      DATABASE::"Resource Group", "Resource Group No.",
                      DATABASE::Job, "Job No.");
                    exit;
                end;

                Res.Get("Resource No.");
                Res.CheckResourcePrivacyBlocked(false);
                Res.TestField(Blocked, false);
                Description := Res.Name;
                "Direct Unit Cost" := Res."Direct Unit Cost";
                "Unit Cost" := Res."Unit Cost";
                "Unit Price" := Res."Unit Price";
                "Resource Group No." := Res."Resource Group No.";
                "Work Type Code" := '';
                "Gen. Prod. Posting Group" := Res."Gen. Prod. Posting Group";
                Validate("Unit of Measure Code", Res."Base Unit of Measure");

                if not "System-Created Entry" then
                    if "Time Sheet No." = '' then
                        Res.TestField("Use Time Sheet", false);

                CreateDim(
                  DATABASE::Resource, "Resource No.",
                  DATABASE::"Resource Group", "Resource Group No.",
                  DATABASE::Job, "Job No.");
            end;
        }
        field(7; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            Editable = false;
            TableRelation = "Resource Group";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Resource Group", "Resource Group No.",
                  DATABASE::Resource, "Resource No.",
                  DATABASE::Job, "Job No.");
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                ResourceUnitOfMeasure: Record "Resource Unit of Measure";
            begin
                if "Resource No." <> '' then begin
                    if WorkType.Get("Work Type Code") then
                        "Unit of Measure Code" := WorkType."Unit of Measure Code"
                    else begin
                        Res.Get("Resource No.");
                        "Unit of Measure Code" := Res."Base Unit of Measure";
                    end;

                    if "Unit of Measure Code" = '' then begin
                        Res.Get("Resource No.");
                        "Unit of Measure Code" := Res."Base Unit of Measure"
                    end;
                    ResourceUnitOfMeasure.Get("Resource No.", "Unit of Measure Code");
                    "Qty. per Unit of Measure" := ResourceUnitOfMeasure."Qty. per Unit of Measure";

                    FindResUnitCost;
                    FindResPrice;
                end;
            end;
        }
        field(10; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;

            trigger OnValidate()
            begin
                FindResPrice;

                CreateDim(
                  DATABASE::Job, "Job No.",
                  DATABASE::Resource, "Resource No.",
                  DATABASE::"Resource Group", "Resource Group No.");
            end;
        }
        field(11; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Resource Unit of Measure".Code WHERE("Resource No." = FIELD("Resource No."));

            trigger OnValidate()
            var
                ResourceUnitOfMeasure: Record "Resource Unit of Measure";
            begin
                if CurrFieldNo <> FieldNo("Work Type Code") then
                    TestField("Work Type Code", '');

                if "Unit of Measure Code" = '' then begin
                    Res.Get("Resource No.");
                    "Unit of Measure Code" := Res."Base Unit of Measure"
                end;
                ResourceUnitOfMeasure.Get("Resource No.", "Unit of Measure Code");
                "Qty. per Unit of Measure" := ResourceUnitOfMeasure."Qty. per Unit of Measure";

                FindResUnitCost;
                FindResPrice;

                Validate(Quantity);
            end;
        }
        field(12; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Unit Cost");
                Validate("Unit Price");
            end;
        }
        field(13; "Direct Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;
        }
        field(14; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            MinValue = 0;

            trigger OnValidate()
            begin
                "Total Cost" := Quantity * "Unit Cost";
            end;
        }
        field(15; "Total Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Cost';

            trigger OnValidate()
            begin
                TestField(Quantity);
                GetGLSetup;
                "Unit Cost" := Round("Total Cost" / Quantity, GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(16; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                "Total Price" := Quantity * "Unit Price";
            end;
        }
        field(17; "Total Price"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Price';

            trigger OnValidate()
            begin
                TestField(Quantity);
                GetGLSetup;
                "Unit Price" := Round("Total Price" / Quantity, GLSetup."Unit-Amount Rounding Precision");
            end;
        }
        field(18; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(19; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(21; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(23; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Res. Journal Batch".Name WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(24; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(25; "Recurring Method"; Option)
        {
            BlankZero = true;
            Caption = 'Recurring Method';
            OptionCaption = ',Fixed,Variable';
            OptionMembers = ,"Fixed",Variable;
        }
        field(26; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(27; "Recurring Frequency"; DateFormula)
        {
            Caption = 'Recurring Frequency';
        }
        field(28; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(29; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(30; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(31; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(32; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(33; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Customer';
            OptionMembers = " ",Customer;
        }
        field(34; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = IF ("Source Type" = CONST(Customer)) Customer."No.";
        }
        field(35; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
        }
        field(90; "Order Type"; Option)
        {
            Caption = 'Order Type';
            Editable = false;
            OptionCaption = ' ,Production,Transfer,Service,Assembly';
            OptionMembers = " ",Production,Transfer,Service,Assembly;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            Editable = false;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(950; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(951; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
            TableRelation = "Time Sheet Line"."Line No." WHERE("Time Sheet No." = FIELD("Time Sheet No."));
        }
        field(952; "Time Sheet Date"; Date)
        {
            Caption = 'Time Sheet Date';
            TableRelation = "Time Sheet Detail".Date WHERE("Time Sheet No." = FIELD("Time Sheet No."),
                                                            "Time Sheet Line No." = FIELD("Time Sheet Line No."));
        }
        field(959; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable;
        ResJnlTemplate.Get("Journal Template Name");
        ResJnlBatch.Get("Journal Template Name", "Journal Batch Name");

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlLine: Record "Res. Journal Line";
        Res: Record Resource;
        ResCost: Record "Resource Cost";
        ResPrice: Record "Resource Price";
        WorkType: Record "Work Type";
        GLSetup: Record "General Ledger Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        GLSetupRead: Boolean;

    local procedure FindResUnitCost()
    begin
        ResCost.Init;
        ResCost.Code := "Resource No.";
        ResCost."Work Type Code" := "Work Type Code";
        CODEUNIT.Run(CODEUNIT::"Resource-Find Cost", ResCost);
        "Direct Unit Cost" := ResCost."Direct Unit Cost" * "Qty. per Unit of Measure";
        "Unit Cost" := ResCost."Unit Cost" * "Qty. per Unit of Measure";
        Validate("Unit Cost");
    end;

    local procedure FindResPrice()
    begin
        ResPrice.Init;
        ResPrice.Code := "Resource No.";
        ResPrice."Work Type Code" := "Work Type Code";
        CODEUNIT.Run(CODEUNIT::"Resource-Find Price", ResPrice);
        "Unit Price" := ResPrice."Unit Price" * "Qty. per Unit of Measure";
        Validate("Unit Price");
    end;

    procedure EmptyLine(): Boolean
    begin
        exit(("Resource No." = '') and (Quantity = 0));
    end;

    procedure SetUpNewLine(LastResJnlLine: Record "Res. Journal Line")
    begin
        ResJnlTemplate.Get("Journal Template Name");
        ResJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        ResJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if ResJnlLine.FindFirst then begin
            "Posting Date" := LastResJnlLine."Posting Date";
            "Document Date" := LastResJnlLine."Posting Date";
            "Document No." := LastResJnlLine."Document No.";
        end else begin
            "Posting Date" := WorkDate;
            "Document Date" := WorkDate;
            if ResJnlBatch."No. Series" <> '' then begin
                Clear(NoSeriesMgt);
                "Document No." := NoSeriesMgt.TryGetNextNo(ResJnlBatch."No. Series", "Posting Date");
            end;
        end;
        "Recurring Method" := LastResJnlLine."Recurring Method";
        "Source Code" := ResJnlTemplate."Source Code";
        "Reason Code" := ResJnlBatch."Reason Code";
        "Posting No. Series" := ResJnlBatch."Posting No. Series";

        OnAfterSetUpNewLine(Rec, LastResJnlLine);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, TableID, No, "Source Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure CopyDocumentFields(DocNo: Code[20]; ExtDocNo: Text[35]; SourceCode: Code[10]; NoSeriesCode: Code[20])
    begin
        "Document No." := DocNo;
        "External Document No." := ExtDocNo;
        "Source Code" := SourceCode;
        if NoSeriesCode <> '' then
            "Posting No. Series" := NoSeriesCode;
    end;

    procedure CopyFromSalesHeader(SalesHeader: Record "Sales Header")
    begin
        "Posting Date" := SalesHeader."Posting Date";
        "Document Date" := SalesHeader."Document Date";
        "Reason Code" := SalesHeader."Reason Code";

        OnAfterCopyResJnlLineFromSalesHeader(SalesHeader, Rec);
    end;

    procedure CopyFromSalesLine(SalesLine: Record "Sales Line")
    begin
        "Resource No." := SalesLine."No.";
        Description := SalesLine.Description;
        "Source Type" := "Source Type"::Customer;
        "Source No." := SalesLine."Sell-to Customer No.";
        "Work Type Code" := SalesLine."Work Type Code";
        "Job No." := SalesLine."Job No.";
        "Unit of Measure Code" := SalesLine."Unit of Measure Code";
        "Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := SalesLine."Dimension Set ID";
        "Gen. Bus. Posting Group" := SalesLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        "Entry Type" := "Entry Type"::Sale;
        "Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
        Quantity := -SalesLine."Qty. to Invoice";
        "Unit Cost" := SalesLine."Unit Cost (LCY)";
        "Total Cost" := SalesLine."Unit Cost (LCY)" * Quantity;
        "Unit Price" := SalesLine."Unit Price";
        "Total Price" := -SalesLine.Amount;

        OnAfterCopyResJnlLineFromSalesLine(SalesLine, Rec);
    end;

    procedure CopyFromServHeader(ServiceHeader: Record "Service Header")
    begin
        "Document Date" := ServiceHeader."Document Date";
        "Reason Code" := ServiceHeader."Reason Code";
        "Order No." := ServiceHeader."No.";

        OnAfterCopyResJnlLineFromServHeader(ServiceHeader, Rec);
    end;

    procedure CopyFromServLine(ServiceLine: Record "Service Line")
    begin
        "Posting Date" := ServiceLine."Posting Date";
        "Order Type" := "Order Type"::Service;
        "Order Line No." := ServiceLine."Line No.";
        "Resource No." := ServiceLine."No.";
        Description := ServiceLine.Description;
        "Work Type Code" := ServiceLine."Work Type Code";
        "Shortcut Dimension 1 Code" := ServiceLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ServiceLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ServiceLine."Dimension Set ID";
        "Unit of Measure Code" := ServiceLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServiceLine."Qty. per Unit of Measure";
        "Gen. Bus. Posting Group" := ServiceLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ServiceLine."Gen. Prod. Posting Group";
        "Source Type" := "Source Type"::Customer;
        "Source No." := ServiceLine."Customer No.";
        "Time Sheet No." := ServiceLine."Time Sheet No.";
        "Time Sheet Line No." := ServiceLine."Time Sheet Line No.";
        "Time Sheet Date" := ServiceLine."Time Sheet Date";
        "Job No." := ServiceLine."Job No.";

        OnAfterCopyResJnlLineFromServLine(ServiceLine, Rec);
    end;

    procedure CopyFromServShptHeader(ServShptHeader: Record "Service Shipment Header")
    begin
        "Document Date" := ServShptHeader."Document Date";
        "Reason Code" := ServShptHeader."Reason Code";
        "Source Type" := "Source Type"::Customer;
        "Source No." := ServShptHeader."Customer No.";

        OnAfterCopyResJnlLineFromServShptHeader(ServShptHeader, Rec);
    end;

    procedure CopyFromServShptLine(ServShptLine: Record "Service Shipment Line")
    begin
        "Posting Date" := ServShptLine."Posting Date";
        "Resource No." := ServShptLine."No.";
        Description := ServShptLine.Description;
        "Work Type Code" := ServShptLine."Work Type Code";
        "Unit of Measure Code" := ServShptLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ServShptLine."Qty. per Unit of Measure";
        "Shortcut Dimension 1 Code" := ServShptLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ServShptLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ServShptLine."Dimension Set ID";
        "Gen. Bus. Posting Group" := ServShptLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ServShptLine."Gen. Prod. Posting Group";
        "Entry Type" := "Entry Type"::Usage;

        OnAfterCopyResJnlLineFromServShptLine(ServShptLine, Rec);
    end;

    procedure CopyFromJobJnlLine(JobJnlLine: Record "Job Journal Line")
    begin
        "Entry Type" := JobJnlLine."Entry Type";
        "Document No." := JobJnlLine."Document No.";
        "External Document No." := JobJnlLine."External Document No.";
        "Posting Date" := JobJnlLine."Posting Date";
        "Document Date" := JobJnlLine."Document Date";
        "Resource No." := JobJnlLine."No.";
        Description := JobJnlLine.Description;
        "Work Type Code" := JobJnlLine."Work Type Code";
        "Job No." := JobJnlLine."Job No.";
        "Shortcut Dimension 1 Code" := JobJnlLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := JobJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := JobJnlLine."Dimension Set ID";
        "Unit of Measure Code" := JobJnlLine."Unit of Measure Code";
        "Source Code" := JobJnlLine."Source Code";
        "Gen. Bus. Posting Group" := JobJnlLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := JobJnlLine."Gen. Prod. Posting Group";
        "Posting No. Series" := JobJnlLine."Posting No. Series";
        "Reason Code" := JobJnlLine."Reason Code";
        "Resource Group No." := JobJnlLine."Resource Group No.";
        "Recurring Method" := JobJnlLine."Recurring Method";
        "Expiration Date" := JobJnlLine."Expiration Date";
        "Recurring Frequency" := JobJnlLine."Recurring Frequency";
        Quantity := JobJnlLine.Quantity;
        "Qty. per Unit of Measure" := JobJnlLine."Qty. per Unit of Measure";
        "Direct Unit Cost" := JobJnlLine."Direct Unit Cost (LCY)";
        "Unit Cost" := JobJnlLine."Unit Cost (LCY)";
        "Total Cost" := JobJnlLine."Total Cost (LCY)";
        "Unit Price" := JobJnlLine."Unit Price (LCY)";
        "Total Price" := JobJnlLine."Line Amount (LCY)";
        "Time Sheet No." := JobJnlLine."Time Sheet No.";
        "Time Sheet Line No." := JobJnlLine."Time Sheet Line No.";
        "Time Sheet Date" := JobJnlLine."Time Sheet Date";

        OnAfterCopyResJnlLineFromJobJnlLine(Rec, JobJnlLine);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get;
        GLSetupRead := true;
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        ResJournalBatch: Record "Res. Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                ResJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            ResJournalBatch.SetFilter(Name, BatchFilter);
            ResJournalBatch.FindFirst;
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromSalesHeader(var SalesHeader: Record "Sales Header"; var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromSalesLine(var SalesLine: Record "Sales Line"; var ResJnlLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromServHeader(var ServiceHeader: Record "Service Header"; var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromServLine(var ServLine: Record "Service Line"; var ResJnlLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromServShptHeader(var ServiceShipmentHeader: Record "Service Shipment Header"; var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromServShptLine(var ServShptLine: Record "Service Shipment Line"; var ResJnlLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyResJnlLineFromJobJnlLine(var ResJnlLine: Record "Res. Journal Line"; var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var ResJournalLine: Record "Res. Journal Line"; var FieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ResJournalLine: Record "Res. Journal Line"; LastResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ResJournalLine: Record "Res. Journal Line"; xResJournalLine: Record "Res. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ResJournalLine: Record "Res. Journal Line"; xResJournalLine: Record "Res. Journal Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;
}

