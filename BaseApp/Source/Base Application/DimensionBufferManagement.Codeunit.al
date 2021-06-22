codeunit 411 "Dimension Buffer Management"
{

    trigger OnRun()
    begin
    end;

    var
        DimensionIDBuffer: Record "Dimension ID Buffer" temporary;
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimEntryBuf: Record "Dimension Entry Buffer" temporary;
        NextDimBufNo: Integer;

    procedure InsertDimensions(var DimBuf: Record "Dimension Buffer"): Integer
    var
        NewEntryNo: Integer;
    begin
        if DimBuf.Find('-') then begin
            TempDimBuf.Reset();
            if TempDimBuf.Find('+') then
                NewEntryNo := TempDimBuf."Entry No." + 1
            else
                NewEntryNo := 1;
            InsertDimensionsUsingEntryNo(DimBuf, NewEntryNo);
            exit(NewEntryNo);
        end;
        exit(0);
    end;

    procedure InsertDimensionsUsingEntryNo(var DimBuf: Record "Dimension Buffer"; EntryNo: Integer)
    var
        DimCount: Integer;
    begin
        DimCount := DimBuf.Count();
        if DimBuf.Find('-') then
            repeat
                TempDimBuf.Init();
                TempDimBuf := DimBuf;
                TempDimBuf."Entry No." := EntryNo;
                TempDimBuf."No. Of Dimensions" := DimCount;
                TempDimBuf.Insert();
            until DimBuf.Next = 0;
    end;

    procedure FindDimensions(var DimBuf: Record "Dimension Buffer"): Integer
    begin
        exit(FindDimensionsKnownDimBufCount(DimBuf, DimBuf.Count));
    end;

    procedure FindDimensionsKnownDimBufCount(var DimBuf: Record "Dimension Buffer"; DimBufCount: Integer): Integer
    var
        Found: Boolean;
        EndOfDimBuf: Boolean;
        EndOfTempDimBuf: Boolean;
        PrevEntryNo: Integer;
    begin
        if not DimBuf.Find('-') then
            exit(0);

        TempDimBuf.Reset();
        TempDimBuf.SetCurrentKey("No. Of Dimensions");
        TempDimBuf.SetRange("No. Of Dimensions", DimBufCount);
        TempDimBuf.SetRange("Table ID", DimBuf."Table ID");
        TempDimBuf.SetRange("Dimension Code", DimBuf."Dimension Code");
        TempDimBuf.SetRange("Dimension Value Code", DimBuf."Dimension Value Code");
        if not TempDimBuf.Find('-') then begin
            TempDimBuf.Reset();
            exit(0);
        end;
        if TempDimBuf."No. Of Dimensions" = 1 then begin
            TempDimBuf.Reset();
            exit(TempDimBuf."Entry No.");
        end;

        DimBuf.Next;
        while (not EndOfTempDimBuf) and (not Found) do begin
            PrevEntryNo := TempDimBuf."Entry No.";
            EndOfDimBuf := false;
            TempDimBuf.SetFilter("Entry No.", '>=%1', TempDimBuf."Entry No.");
            repeat
                TempDimBuf.SetRange("Dimension Code", DimBuf."Dimension Code");
                TempDimBuf.SetRange("Dimension Value Code", DimBuf."Dimension Value Code");
                EndOfTempDimBuf := not TempDimBuf.Find('-');
                if not EndOfTempDimBuf then
                    EndOfDimBuf := DimBuf.Next = 0;
            until EndOfTempDimBuf or EndOfDimBuf or (PrevEntryNo <> TempDimBuf."Entry No.");
            if EndOfDimBuf and (PrevEntryNo = TempDimBuf."Entry No.") then
                Found := true
            else
                DimBuf.Find('-');
        end;
        TempDimBuf.Reset();
        if Found then
            exit(TempDimBuf."Entry No.");

        exit(0);
    end;

    procedure GetDimensions(EntryNo: Integer; var DimBuf: Record "Dimension Buffer"): Boolean
    begin
        TempDimBuf.SetRange("Entry No.", EntryNo);
        if not TempDimBuf.Find('-') then
            exit(false);

        repeat
            DimBuf.Init();
            DimBuf := TempDimBuf;
            DimBuf.Insert();
        until TempDimBuf.Next = 0;
        exit(true);
    end;

    procedure DeleteAllDimensions()
    begin
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
    end;

    procedure CollectDimEntryNo(var SelectedDim: Record "Selected Dimension"; DimSetID: Integer; EntryNo: Integer; ForgetDimEntryNo: Integer; DoCollect: Boolean; var DimEntryNo: Integer)
    var
        TempDimBuf: Record "Dimension Buffer" temporary;
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if SelectedDim.Find('-') then begin
            repeat
                if DimSetEntry.Get(DimSetID, SelectedDim."Dimension Code") then begin
                    TempDimBuf."Dimension Code" := DimSetEntry."Dimension Code";
                    TempDimBuf."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                    TempDimBuf.Insert();
                end;
            until SelectedDim.Next = 0;
            DimEntryNo := FindDimensions(TempDimBuf);
            if DimEntryNo = 0 then
                DimEntryNo := InsertDimensions(TempDimBuf);
        end else
            DimEntryNo := 0;

        if (DimEntryNo <> ForgetDimEntryNo) and DoCollect then begin
            TempDimEntryBuf."No." := EntryNo;
            TempDimEntryBuf."Dimension Entry No." := DimEntryNo;
            TempDimEntryBuf.Insert();
        end;
    end;

    procedure FindFirstDimEntryNo(var DimEntryNo: Integer; var EntryNo: Integer): Boolean
    var
        Found: Boolean;
    begin
        TempDimEntryBuf.SetCurrentKey("Dimension Entry No.");
        Found := TempDimEntryBuf.Find('-');
        DimEntryNo := TempDimEntryBuf."Dimension Entry No.";
        EntryNo := TempDimEntryBuf."No.";
        exit(Found);
    end;

    procedure NextDimEntryNo(var DimEntryNo: Integer; var EntryNo: Integer): Boolean
    var
        Found: Boolean;
    begin
        Found := TempDimEntryBuf.Next <> 0;
        DimEntryNo := TempDimEntryBuf."Dimension Entry No.";
        EntryNo := TempDimEntryBuf."No.";
        exit(Found);
    end;

    procedure DeleteAllDimEntryNo()
    begin
        TempDimEntryBuf.DeleteAll();
    end;

    procedure GetDimensionId(var Dimbuf: Record "Dimension Buffer"): Integer
    var
        NewDimensionComb: Boolean;
    begin
        if not Dimbuf.FindFirst then
            exit(0);

        if NextDimBufNo = 0 then
            NextDimBufNo := 1;

        NewDimensionComb := false;
        DimensionIDBuffer.ID := 0;
        repeat
            if NewDimensionComb then
                InsertDimIdBuf(Dimbuf)
            else
                if not DimensionIDBuffer.Get(DimensionIDBuffer.ID, Dimbuf."Dimension Code", Dimbuf."Dimension Value Code") then begin
                    NewDimensionComb := true;
                    InsertDimIdBuf(Dimbuf);
                end;
        until Dimbuf.Next = 0;

        exit(DimensionIDBuffer.ID);
    end;

    procedure RetrieveDimensions(DimId: Integer; var DimBuf: Record "Dimension Buffer")
    begin
        DimBuf.Reset();
        DimBuf.DeleteAll();

        if DimId = 0 then
            exit;

        DimensionIDBuffer.SetCurrentKey(ID);
        DimensionIDBuffer.SetRange(ID, DimId);
        repeat
            DimensionIDBuffer.FindFirst;
            DimBuf.Init();
            DimBuf."Entry No." := DimId;
            DimBuf."Dimension Code" := DimensionIDBuffer."Dimension Code";
            DimBuf."Dimension Value Code" := DimensionIDBuffer."Dimension Value";
            DimBuf.Insert();
            DimensionIDBuffer.SetRange(ID, DimensionIDBuffer."Parent ID");
        until DimensionIDBuffer."Parent ID" = 0;
    end;

    local procedure InsertDimIdBuf(var DimBuf: Record "Dimension Buffer")
    begin
        DimensionIDBuffer."Parent ID" := DimensionIDBuffer.ID;
        DimensionIDBuffer."Dimension Code" := DimBuf."Dimension Code";
        DimensionIDBuffer."Dimension Value" := DimBuf."Dimension Value Code";
        DimensionIDBuffer.ID := NextDimBufNo;
        NextDimBufNo += 1;
        DimensionIDBuffer.Insert();
    end;
}

