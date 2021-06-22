codeunit 7151 ItemAViewEntryToValueEntries
{

    trigger OnRun()
    begin
    end;

    var
        ItemAnalysisView: Record "Item Analysis View";
        GLSetup: Record "General Ledger Setup";
        DimSetEntry: Record "Dimension Set Entry";

    procedure GetValueEntries(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; var TempValueEntry: Record "Value Entry")
    var
        ValueEntry: Record "Value Entry";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        StartDate: Date;
        EndDate: Date;
        GlobalDimValue: Code[20];
    begin
        ItemAnalysisView.Get(
          ItemAnalysisViewEntry."Analysis Area",
          ItemAnalysisViewEntry."Analysis View Code");

        if ItemAnalysisView."Date Compression" = ItemAnalysisView."Date Compression"::None then begin
            if ValueEntry.Get(ItemAnalysisViewEntry."Entry No.") then begin
                TempValueEntry := ValueEntry;
                TempValueEntry.Insert();
            end;
            exit;
        end;

        GLSetup.Get();

        StartDate := ItemAnalysisViewEntry."Posting Date";
        EndDate := StartDate;

        with ItemAnalysisView do
            if StartDate < "Starting Date" then
                StartDate := 0D
            else
                if (ItemAnalysisViewEntry."Posting Date" = NormalDate(ItemAnalysisViewEntry."Posting Date")) and
                   not ("Date Compression" in ["Date Compression"::None, "Date Compression"::Day])
                then
                    case "Date Compression" of
                        "Date Compression"::Week:
                            EndDate := ItemAnalysisViewEntry."Posting Date" + 6;
                        "Date Compression"::Month:
                            EndDate := CalcDate('<+1M-1D>', ItemAnalysisViewEntry."Posting Date");
                        "Date Compression"::Quarter:
                            EndDate := CalcDate('<+3M-1D>', ItemAnalysisViewEntry."Posting Date");
                        "Date Compression"::Year:
                            EndDate := CalcDate('<+1Y-1D>', ItemAnalysisViewEntry."Posting Date");
                    end;

        with ValueEntry do begin
            SetCurrentKey("Item No.", "Posting Date");
            SetRange("Item No.", ItemAnalysisViewEntry."Item No.");
            SetRange("Posting Date", StartDate, EndDate);
            SetRange("Entry No.", 0, ItemAnalysisView."Last Entry No.");

            if GetGlobalDimValue(GLSetup."Global Dimension 1 Code", ItemAnalysisViewEntry, GlobalDimValue) then
                SetRange("Global Dimension 1 Code", GlobalDimValue)
            else
                if ItemAnalysisViewFilter.Get(
                     ItemAnalysisView."Analysis Area",
                     ItemAnalysisViewEntry."Analysis View Code",
                     GLSetup."Global Dimension 1 Code")
                then
                    SetFilter("Global Dimension 1 Code", ItemAnalysisViewFilter."Dimension Value Filter");

            if GetGlobalDimValue(GLSetup."Global Dimension 2 Code", ItemAnalysisViewEntry, GlobalDimValue) then
                SetRange("Global Dimension 2 Code", GlobalDimValue)
            else
                if ItemAnalysisViewFilter.Get(
                     ItemAnalysisView."Analysis Area",
                     ItemAnalysisViewEntry."Analysis View Code",
                     GLSetup."Global Dimension 2 Code")
                then
                    SetFilter("Global Dimension 2 Code", ItemAnalysisViewFilter."Dimension Value Filter");

            if Find('-') then
                repeat
                    if DimEntryOK("Dimension Set ID", ItemAnalysisView."Dimension 1 Code", ItemAnalysisViewEntry."Dimension 1 Value Code") and
                       DimEntryOK("Dimension Set ID", ItemAnalysisView."Dimension 2 Code", ItemAnalysisViewEntry."Dimension 2 Value Code") and
                       DimEntryOK("Dimension Set ID", ItemAnalysisView."Dimension 3 Code", ItemAnalysisViewEntry."Dimension 3 Value Code") and
                       UpdateItemAnalysisView.DimSetIDInFilter("Dimension Set ID", ItemAnalysisView)
                    then
                        if ((ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Sales) and
                            ("Item Ledger Entry Type" = "Item Ledger Entry Type"::Sale) and
                            ("Entry Type" <> "Entry Type"::Revaluation)) or
                           ((ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Purchase) and
                            ("Item Ledger Entry Type" = "Item Ledger Entry Type"::Purchase)) or
                           ((ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Inventory) and
                            ("Item Ledger Entry Type" <> "Item Ledger Entry Type"::" "))
                        then
                            if not TempValueEntry.Get("Entry No.") then begin
                                TempValueEntry := ValueEntry;
                                TempValueEntry.Insert();
                            end;
                until Next() = 0;
        end;
    end;

    local procedure DimEntryOK(DimSetID: Integer; Dim: Code[20]; DimValue: Code[20]): Boolean
    begin
        if Dim = '' then
            exit(true);

        if DimSetEntry.Get(DimSetID, Dim) then
            exit(DimSetEntry."Dimension Value Code" = DimValue);

        exit(DimValue = '');
    end;

    local procedure GetGlobalDimValue(GlobalDim: Code[20]; var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; var GlobalDimValue: Code[20]): Boolean
    var
        IsGlobalDim: Boolean;
    begin
        case GlobalDim of
            ItemAnalysisView."Dimension 1 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := ItemAnalysisViewEntry."Dimension 1 Value Code";
                end;
            ItemAnalysisView."Dimension 2 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := ItemAnalysisViewEntry."Dimension 2 Value Code";
                end;
            ItemAnalysisView."Dimension 3 Code":
                begin
                    IsGlobalDim := true;
                    GlobalDimValue := ItemAnalysisViewEntry."Dimension 3 Value Code";
                end;
        end;
        exit(IsGlobalDim);
    end;
}

