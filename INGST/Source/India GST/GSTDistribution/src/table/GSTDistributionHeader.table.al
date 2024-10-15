table 18203 "GST Distribution Header"
{
    Caption = 'Distribution Header';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "From GSTIN No."; Code[20])
        {
            Caption = 'From GSTIN No.';
            Editable = false;
            TableRelation = "GST Registration Nos." where("Input Service Distributor" = filter(true));
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(10; "Dist. Document Type"; Enum "BankCharges DocumentType")
        {
            Caption = 'Dist. Document Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; Reversal; Boolean)
        {
            Caption = 'Reversal';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12; "Reversal Invoice No."; Code[20])
        {
            Caption = 'Reversal Invoice No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Posted GST Distribution Header"
                where(
                    Reversal = const(false),
                    "Completely Reversed" = const(false));
        }
        field(13; "ISD Document Type"; Enum "Adjustment Document Type")
        {
            Caption = 'ISD Document Type';
            Editable = false;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "From Location Code"; Code[10])
        {
            Caption = 'From Location Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = Location where("GST Input Service Distributor" = filter(true));

        }
        field(16; "Dist. Credit Type"; Enum "GST Distribution Credit Type")
        {
            Caption = 'Dist. Credit Type';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                TestField("Total Amout Applied for Dist.", 0);
            end;
        }
        field(17; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "Total Amout Applied for Dist."; Decimal)
        {
            Caption = 'Total Amout Applied for Dist.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "Distribution Basis"; Text[50])
        {
            Caption = 'Distribution Basis';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(25; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(26; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }

        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
            DataClassification = EndUserIdentifiableInformation;

            trigger OnLookup()
            begin
                ShowDocDim();
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    procedure AssistEdit(GSTDistributionHeader: Record "GST Distribution Header"): Boolean
    begin
        Copy(Rec);
        GLSetup.Get();
        GLSetup.TestField("GST Distribution Nos.");
        if NoSeriesManagement.SelectSeries(GLSetup."GST Distribution Nos.", "No. Series", "No. Series") then begin
            NoSeriesManagement.SetSeries("No.");
            Rec := GSTDistributionHeader;
            exit(true);
        end;
    end;

    procedure ShowDocDim()
    var
        DimMgt: Codeunit DimensionManagement;
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" := DimMgt.EditDimensionSet(
            "Dimension Set ID",
            StrSubstNo(DimensionSetMsg, "No."),
            "Shortcut Dimension 1 Code",
            "Shortcut Dimension 2 Code");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if GSTDistributionLinesExist() then
                UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure GSTDistributionLinesExist(): Boolean
    var
        GSTDistributionLine: Record "GST Distribution Line";
    begin
        GSTDistributionLine.SetRange("Distribution No.", "No.");
        exit(not GSTDistributionLine.IsEmpty());
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        GSTDistributionLine: Record "GST Distribution Line";
        DimMgt: Codeunit DimensionManagement;
        NewDimSetID: Integer;
    begin
        if NewParentDimSetID = OldParentDimSetID then
            exit;
        if not CONFIRM(UpdateDimQst) then
            exit;

        GSTDistributionLine.SetRange("Distribution No.", "No.");
        GSTDistributionLine.LockTable();
        if GSTDistributionLine.FindSet() then
            repeat
                NewDimSetID := DimMgt.GetDeltaDimSetID(
                    GSTDistributionLine."Dimension Set ID",
                    NewParentDimSetID,
                    OldParentDimSetID);
                if GSTDistributionLine."Dimension Set ID" <> NewDimSetID then begin
                    GSTDistributionLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                        GSTDistributionLine."Dimension Set ID",
                        GSTDistributionLine."Shortcut Dimension 1 Code",
                        GSTDistributionLine."Shortcut Dimension 2 Code");
                    GSTDistributionLine.Modify();
                end;
            until GSTDistributionLine.Next() = 0;

    end;

    var
        GLSetup: Record "General Ledger Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        UpdateDimQst: Label 'You may have changed a dimension.Do you want to update the lines?';
        DimensionSetMsg: Label '%1', Comment = '%1 =Dimension Set No.';
}
