codeunit 5674 FADimensionManagement
{

    trigger OnRun()
    begin
    end;

    var
        TempSelectedDim: Record "Selected Dimension" temporary;
        TempSelectedDim2: Record "Selected Dimension" temporary;
        TempSelectedDim3: Record "Selected Dimension" temporary;

        Text000: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5';
        Text001: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5';

    procedure GetSelectedDim(var SelectedDim: Record "Selected Dimension")
    begin
        Clear(TempSelectedDim);
        TempSelectedDim.Reset();
        TempSelectedDim.DeleteAll();
        if SelectedDim.Find('-') then
            repeat
                TempSelectedDim."Dimension Code" := SelectedDim."Dimension Code";
                TempSelectedDim.Insert();
            until SelectedDim.Next() = 0;
    end;

    procedure GetDimensions(var DimBuf: Record "Dimension Buffer")
    begin
        if TempSelectedDim2.Find('-') then
            repeat
                DimBuf."Dimension Code" := TempSelectedDim2."Dimension Code";
                DimBuf."Dimension Value Code" := TempSelectedDim2."New Dimension Value Code";
                DimBuf.Insert();
            until TempSelectedDim2.Next() = 0;
    end;

    procedure CheckFAAllocDim(var FAAlloc: Record "FA Allocation"; DimSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFAAllocDim(FAAlloc, DimSetID, IsHandled);
        if IsHandled then
            exit;

        if not DimMgt.CheckDimIDComb(DimSetID) then
            Error(
              Text000,
              FAAlloc.TableCaption(), FAAlloc.Code, FAAlloc."Allocation Type", FAAlloc."Line No.",
              DimMgt.GetDimCombErr());

        TableID[1] := DimMgt.TypeToTableID1(0);
        No[1] := FAAlloc."Account No.";

        if not DimMgt.CheckDimValuePosting(TableID, No, DimSetID) then
            Error(
              Text001,
              FAAlloc.TableCaption(), FAAlloc.Code, FAAlloc."Allocation Type", FAAlloc."Line No.",
              DimMgt.GetDimValuePostingErr());
    end;

    procedure GetFALedgEntryDimID(Type: Integer; DimSetID: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if Type = 0 then begin
            Clear(TempSelectedDim2);
            TempSelectedDim2.Reset();
            TempSelectedDim2.DeleteAll();
        end;
        if Type = 1 then begin
            Clear(TempSelectedDim3);
            TempSelectedDim3.Reset();
            TempSelectedDim3.DeleteAll();
        end;
        with DimSetEntry do begin
            SetRange("Dimension Set ID", DimSetID);
            if Find('-') then
                repeat
                    TempSelectedDim.SetRange("Dimension Code", "Dimension Code");
                    if TempSelectedDim.FindFirst() then begin
                        if Type = 0 then begin
                            TempSelectedDim2."Dimension Code" := "Dimension Code";
                            TempSelectedDim2."New Dimension Value Code" := "Dimension Value Code";
                            TempSelectedDim2.Insert();
                        end;
                        if Type = 1 then begin
                            TempSelectedDim3."Dimension Code" := "Dimension Code";
                            TempSelectedDim3."New Dimension Value Code" := "Dimension Value Code";
                            TempSelectedDim3.Insert();
                        end;
                    end;
                until Next() = 0;
        end;
    end;

    procedure TestEqualFALedgEntryDimID(DimSetID: Integer): Boolean
    begin
        GetFALedgEntryDimID(1, DimSetID);
        if TempSelectedDim2.Count <> TempSelectedDim3.Count then
            exit(false);
        if TempSelectedDim2.Find('-') then
            repeat
                TempSelectedDim3.SetRange("Dimension Code", TempSelectedDim2."Dimension Code");
                if not TempSelectedDim3.FindFirst() then
                    exit(false);
                if TempSelectedDim2."New Dimension Value Code" <> TempSelectedDim3."New Dimension Value Code" then
                    exit(false);
            until TempSelectedDim2.Next() = 0;
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFAAllocDim(var FAAlloc: Record "FA Allocation"; DimSetID: Integer; var IsHandled: Boolean)
    begin
    end;
}

