table 18204 "GST Distribution Line"
{
    Caption = 'GST Distribution Line';

    fields
    {
        field(1; "Distribution No."; Code[20])
        {
            Caption = 'Distribution No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "From GSTIN No."; Code[20])
        {
            Caption = 'GSTIN No.';
            Editable = false;
            TableRelation = "GST Registration Nos."
                where("Input Service Distributor" = filter(true));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "Rcpt. Credit Type"; Enum "GST Distribution Credit Type")
        {
            Caption = 'Rcpt. Credit Type';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                ValidateRcptCreditType();
            end;
        }
        field(20; "From Location Code"; Code[10])
        {
            Caption = 'From Location Code';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(21; "To Location Code"; Code[10])
        {
            Caption = 'To Location Code';
            TableRelation = Location where("GST Input Service Distributor" = filter(false));
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                ValidateToLocationCode();
            end;
        }
        field(22; "To GSTIN No."; Code[20])
        {
            Caption = 'To GSTIN No.';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "Distribution Jurisdiction"; Enum "GST Jurisdiction Type")
        {
            Caption = 'Distribution Jurisdiction';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "Distribution %"; Decimal)
        {
            Caption = 'Distribution %';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                ValidateDistributionPercent();
            end;
        }
        field(25; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(26; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(27; "Distribution Amount"; Decimal)
        {
            Caption = 'Distribution Amount';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
            DataClassification = EndUserIdentifiableInformation;

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
    }

    keys
    {
        key(Key1; "Distribution No.", "Line No.")
        {
            Clustered = true;
        }
    }

    procedure ShowDimensions()
    begin
        TestField("Distribution No.");
        TestField("Line No.");
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo(DistributionMsg, "Distribution No.", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    local procedure ValidateRcptCreditType()
    var
        GSTDistHeader: Record "GST Distribution Header";
        GSTDistLine: Record "GST Distribution Line";
    begin
        GSTDistHeader.Get("Distribution No.");
        if GSTDistHeader.Reversal and ("Rcpt. Credit Type" <> xRec."Rcpt. Credit Type") then
            Error(ChangeRcptCreditTypeErr);

        TestField("To Location Code");
        if "Rcpt. Credit Type" <> "Rcpt. Credit Type"::" " then begin
            GSTDistLine.Reset();
            GSTDistLine.SetRange("Distribution No.", "Distribution No.");
            GSTDistLine.SetRange("To Location Code", "To Location Code");
            GSTDistLine.SetRange("Rcpt. Credit Type", "Rcpt. Credit Type");
            GSTDistLine.SetFilter("Line No.", '<>%1', "Line No.");
            if GSTDistLine.FindFirst() then
                Error(
                    SameToLocationErr,
                    "To Location Code",
                    "Rcpt. Credit Type",
                    GSTDistLine."Line No.");
        end;
    end;

    local procedure ValidateToLocationCode()
    var
        GSTDistHeader: Record "GST Distribution Header";
        Location: Record Location;
        Location2: Record Location;
    begin
        Clear("To GSTIN No.");
        GSTDistHeader.Get("Distribution No.");
        GSTDistHeader.TestField("From Location Code");
        GSTDistHeader.TestField("Posting Date");
        if GSTDistHeader."Dist. Credit Type" = GSTDistHeader."Dist. Credit Type"::" " then
            Error(DistCreditTypeErr);
        "From Location Code" := GSTDistHeader."From Location Code";
        "From GSTIN No." := GSTDistHeader."From GSTIN No.";
        "Posting Date" := GSTDistHeader."Posting Date";
        "Rcpt. Credit Type" := GSTDistHeader."Dist. Credit Type";
        Location.Get("From Location Code");
        if Location2.Get("To Location Code") then begin
            Location2.TestField("State Code");
            "To GSTIN No." := Location2."GST Registration No.";
            if Location."State Code" = Location2."State Code" then
                "Distribution Jurisdiction" := "Distribution Jurisdiction"::Intrastate
            else
                "Distribution Jurisdiction" := "Distribution Jurisdiction"::Interstate;
        end;

        if GSTDistHeader.Reversal then
            if "To Location Code" <> xRec."To Location Code" then
                Error(ChangeToLocErr);
    end;

    local procedure ValidateDistributionPercent()
    var
        GSTDistHeader: Record "GST Distribution Header";
        GSTDistLine: Record "GST Distribution Line";
    begin
        TestField("To Location Code");
        GLSetup.Get();
        GSTDistHeader.Get("Distribution No.");
        GSTDistLine.SetRange("Distribution No.", "Distribution No.");
        GSTDistLine.SetFilter("Line No.", '<>%1', "Line No.");
        GSTDistLine.CalcSums("Distribution %");
        if GSTDistLine."Distribution %" + "Distribution %" > 100 then
            Error(DistPercentTotalErr, FieldName("Distribution %"));
        if ("Distribution %" < 0) or ("Distribution %" > 100) then
            Error(DistPercentRangeErr, FieldName("Distribution %"));
        if "Distribution %" <> 0 then
            "Distribution Amount" :=
              Round(
                  GSTDistHeader."Total Amout Applied for Dist." * "Distribution %" / 100,
                  GLSetup."Amount Rounding Precision")
        else
            "Distribution Amount" := 0;

        if GSTDistHeader.Reversal then
            if "Distribution %" <> xRec."Distribution %" then
                Error(ChangeDistPerErr);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        DimMgt: Codeunit DimensionManagement;
        SameToLocationErr: Label 'To Location Code: %1 and Rcpt. Credit Type: %2 already exists for Line No. %3.', Comment = '%1 = To Location Code, %2 = Rcpt. Credit Type, %3 = Line No.';
        DistPercentRangeErr: Label '%1 must be in between 0 and 100.', Comment = '%1 = Field Name';
        DistPercentTotalErr: Label 'Sum of %1 cannot be more than 100.', Comment = '%1 = Field Name';
        ChangeDistPerErr: Label 'You cannot change Distribution % for GST Distribution Reversal.';
        ChangeRcptCreditTypeErr: Label 'You cannot change Rcpt. Credit Type for GST Distribution Reversal.';
        ChangeToLocErr: Label 'You cannot change To Location Code for GST Distribution Reversal.';
        DistCreditTypeErr: Label 'Dist. Credit Type cannot be blank.';
        DistributionMsg: Label '%1,%2', Comment = '%1 =Distribution No., %2= Line No.';
}

