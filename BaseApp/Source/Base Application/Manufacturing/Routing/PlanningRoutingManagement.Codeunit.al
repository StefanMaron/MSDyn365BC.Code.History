namespace Microsoft.Manufacturing.Routing;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Requisition;

codeunit 99000808 PlanningRoutingManagement
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Circular reference in line %1 when calculating %2. Counted sequences %3. Max. sequences %4.';
#pragma warning restore AA0470
        Text001: Label 'back';
#pragma warning disable AA0470
        Text002: Label 'Actual number of termination processes in line %1 is %2. They should be 1. Check %3.';
        Text003: Label 'Actual number of start processes in line %1 is %2. They should be 1. Check %3.';
        Text004: Label 'Not all routing lines are sequenced backwards on line %1. Check %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NotAllRoutingLineSequencedForwardErr: Label 'Not all routing lines are sequenced forward on line %1. Check the %2.', Comment = '%1: Field(Line No.); %2 Text ErrList:';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'Previous operations for %1 cannot be found.';
        Text007: Label 'Next operations for %1 cannot be found.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        UOMMgt: Codeunit "Unit of Measure Management";
        ErrList: Text[50];

    procedure NeedsCalculation(WkShName: Code[10]; BatchName: Code[10]; LineNo: Integer): Boolean
    var
        PlanningRtngLine: Record "Planning Routing Line";
    begin
        PlanningRtngLine.SetRange("Worksheet Template Name", WkShName);
        PlanningRtngLine.SetRange("Worksheet Batch Name", BatchName);
        PlanningRtngLine.SetRange("Worksheet Line No.", LineNo);
        PlanningRtngLine.SetRange(Recalculate, true);

        exit(PlanningRtngLine.FindFirst());
    end;

    local procedure ErrorInRouting(LineNo: Integer; Direction: Text[20]; ActualSequence: Integer; MaxSequences: Integer)
    begin
        Error(
          Text000,
          LineNo, Direction, ActualSequence, MaxSequences);
    end;

    local procedure InsertInErrList(PlanningRtngLine: Record "Planning Routing Line")
    begin
        if (StrLen(ErrList) + StrLen(PlanningRtngLine."Operation No.") + 1) > MaxStrLen(ErrList) then
            exit;

        if StrLen(ErrList) > 0 then
            ErrList := ErrList + ',' + PlanningRtngLine."Operation No."
        else
            ErrList := PlanningRtngLine."Operation No.";
    end;

    procedure SetRtngLineSequenceBack(RoutingType: Option Serial,Parallel; PlanningRtngLine: Record "Planning Routing Line"; Maxsequences: Integer; Actsequences: Integer; TotalCalculation: Boolean)
    var
        PlanningRtngLine2: Record "Planning Routing Line";
        SequenceNo: Integer;
    begin
        if RoutingType = RoutingType::Parallel then begin
            if (Actsequences - 1) > Maxsequences then
                ErrorInRouting(
                  PlanningRtngLine."Worksheet Line No.", Text001, Actsequences, Maxsequences);

            if TotalCalculation then
                PlanningRtngLine."Sequence No.(Backward)" := 1
            else
                PlanningRtngLine."Sequence No. (Actual)" := 1;

            PlanningRtngLine2.SetRange("Worksheet Template Name", PlanningRtngLine."Worksheet Template Name");
            PlanningRtngLine2.SetRange("Worksheet Batch Name", PlanningRtngLine."Worksheet Batch Name");
            PlanningRtngLine2.SetRange("Worksheet Line No.", PlanningRtngLine."Worksheet Line No.");
            if PlanningRtngLine."Next Operation No." <> '' then begin
                PlanningRtngLine2.SetFilter("Operation No.", PlanningRtngLine."Next Operation No.");
                if PlanningRtngLine2.Find('-') then
                    repeat
                        if TotalCalculation then begin
                            if (PlanningRtngLine2."Sequence No.(Backward)" + 1) > PlanningRtngLine."Sequence No.(Backward)" then
                                PlanningRtngLine."Sequence No.(Backward)" := PlanningRtngLine2."Sequence No.(Backward)" + 1;
                        end else
                            if (PlanningRtngLine2."Sequence No. (Actual)" + 1) > PlanningRtngLine."Sequence No. (Actual)" then
                                PlanningRtngLine."Sequence No. (Actual)" := PlanningRtngLine2."Sequence No. (Actual)" + 1;
                    until PlanningRtngLine2.Next() = 0;
            end;
            PlanningRtngLine.Modify();

            if PlanningRtngLine."Previous Operation No." <> '' then begin
                PlanningRtngLine2.SetFilter("Operation No.", PlanningRtngLine."Previous Operation No.");
                if PlanningRtngLine2.Find('-') then
                    repeat
                        SetRtngLineSequenceBack(
                          RoutingType,
                          PlanningRtngLine2,
                          Maxsequences,
                          Actsequences + 1,
                          TotalCalculation);
                    until PlanningRtngLine2.Next() = 0;
            end;
        end else begin
            SequenceNo := 1;
            PlanningRtngLine2 := PlanningRtngLine;
            PlanningRtngLine2.SetRange("Worksheet Template Name", PlanningRtngLine."Worksheet Template Name");
            PlanningRtngLine2.SetRange("Worksheet Batch Name", PlanningRtngLine."Worksheet Batch Name");
            PlanningRtngLine2.SetRange("Worksheet Line No.", PlanningRtngLine."Worksheet Line No.");
            if PlanningRtngLine2.Find() then
                repeat
                    if TotalCalculation then
                        PlanningRtngLine2."Sequence No.(Backward)" := SequenceNo
                    else
                        PlanningRtngLine2."Sequence No. (Actual)" := SequenceNo;
                    PlanningRtngLine2.Modify();
                    SequenceNo := SequenceNo + 1;
                until PlanningRtngLine2.Next(-1) = 0;
        end;
    end;

    procedure SetRtngLineSequenceForward(RoutingType: Option Serial,Parallel; PlanningRtngLine: Record "Planning Routing Line"; MaxSequences: Integer; ActSequences: Integer; TotalCalculation: Boolean)
    var
        PlanningRtngLine2: Record "Planning Routing Line";
        SequenceNo: Integer;
    begin
        if RoutingType = RoutingType::Parallel then begin
            if ActSequences > MaxSequences then
                ErrorInRouting(
                  PlanningRtngLine."Worksheet Line No.", Text001, ActSequences, MaxSequences);

            if TotalCalculation then
                PlanningRtngLine."Sequence No.(Forward)" := 1
            else
                PlanningRtngLine."Sequence No. (Actual)" := 1;

            PlanningRtngLine2.SetRange("Worksheet Template Name", PlanningRtngLine."Worksheet Template Name");
            PlanningRtngLine2.SetRange("Worksheet Batch Name", PlanningRtngLine."Worksheet Batch Name");
            PlanningRtngLine2.SetRange("Worksheet Line No.", PlanningRtngLine."Worksheet Line No.");
            if PlanningRtngLine."Previous Operation No." <> '' then begin
                PlanningRtngLine2.SetFilter("Operation No.", PlanningRtngLine."Previous Operation No.");
                if PlanningRtngLine2.Find('-') then
                    repeat
                        if TotalCalculation then begin
                            if (PlanningRtngLine2."Sequence No.(Forward)" + 1) > PlanningRtngLine."Sequence No.(Forward)" then
                                PlanningRtngLine."Sequence No.(Forward)" := PlanningRtngLine2."Sequence No.(Forward)" + 1;
                        end else
                            if (PlanningRtngLine2."Sequence No. (Actual)" + 1) > PlanningRtngLine."Sequence No. (Actual)" then
                                PlanningRtngLine."Sequence No. (Actual)" := PlanningRtngLine2."Sequence No. (Actual)" + 1;
                    until PlanningRtngLine2.Next() = 0;
            end;
            PlanningRtngLine.Modify();

            if PlanningRtngLine."Next Operation No." <> '' then begin
                PlanningRtngLine2.SetFilter("Operation No.", PlanningRtngLine."Next Operation No.");
                if PlanningRtngLine2.Find('-') then
                    repeat
                        SetRtngLineSequenceForward(
                          RoutingType,
                          PlanningRtngLine2,
                          MaxSequences,
                          ActSequences + 1,
                          TotalCalculation);
                    until PlanningRtngLine2.Next() = 0;
            end;
        end else begin
            SequenceNo := 1;
            PlanningRtngLine2 := PlanningRtngLine;
            PlanningRtngLine2.SetRange("Worksheet Template Name", PlanningRtngLine."Worksheet Template Name");
            PlanningRtngLine2.SetRange("Worksheet Batch Name", PlanningRtngLine."Worksheet Batch Name");
            PlanningRtngLine2.SetRange("Worksheet Line No.", PlanningRtngLine."Worksheet Line No.");
            if PlanningRtngLine2.Find() then
                repeat
                    if TotalCalculation then
                        PlanningRtngLine2."Sequence No.(Forward)" := SequenceNo
                    else
                        PlanningRtngLine2."Sequence No. (Actual)" := SequenceNo;
                    PlanningRtngLine2.Modify();
                    SequenceNo := SequenceNo + 1;
                until PlanningRtngLine2.Next() = 0;
        end;
    end;

    local procedure CalcSequenceBack(ReqLine: Record "Requisition Line")
    var
        PlanningRtngLine: Record "Planning Routing Line";
        MaxSeq: Integer;
    begin
        PlanningRtngLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", ReqLine."Line No.");

        PlanningRtngLine.ModifyAll("Sequence No.(Backward)", 0);
        PlanningRtngLine.ModifyAll("Fixed Scrap Qty. (Accum.)", 0);
        PlanningRtngLine.ModifyAll("Scrap Factor % (Accumulated)", 0);

        MaxSeq := PlanningRtngLine.Count();

        PlanningRtngLine.SetFilter("Next Operation No.", '%1', '');
        PlanningRtngLine.FindFirst();
        SetRtngLineSequenceBack(ReqLine."Routing Type", PlanningRtngLine, MaxSeq, 1, true);
    end;

    local procedure CalcSequenceForward(ReqLine: Record "Requisition Line")
    var
        PlanningRtngLine: Record "Planning Routing Line";
        MaxSeq: Integer;
    begin
        PlanningRtngLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", ReqLine."Line No.");

        PlanningRtngLine.ModifyAll("Sequence No.(Forward)", 0);

        MaxSeq := PlanningRtngLine.Count();

        PlanningRtngLine.SetFilter("Previous Operation No.", '%1', '');
        PlanningRtngLine.FindFirst();
        SetRtngLineSequenceForward(ReqLine."Routing Type", PlanningRtngLine, MaxSeq, 1, true);
    end;

    procedure CalcSequenceFromActual(PlanningRtngLine: Record "Planning Routing Line"; Direction: Option Forward,Backward; ReqLine: Record "Requisition Line")
    var
        PlanningRtngLine2: Record "Planning Routing Line";
        MaxSeq: Integer;
    begin
        if NeedsCalculation(
             ReqLine."Worksheet Template Name",
             ReqLine."Journal Batch Name",
             ReqLine."Line No.")
        then
            Calculate(ReqLine);

        PlanningRtngLine2.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningRtngLine2.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningRtngLine2.SetRange("Worksheet Line No.", ReqLine."Line No.");
        PlanningRtngLine2.ModifyAll("Sequence No. (Actual)", 0);

        MaxSeq := PlanningRtngLine2.Count();

        case Direction of
            Direction::Forward:
                SetRtngLineSequenceForward(ReqLine."Routing Type", PlanningRtngLine, MaxSeq, 1, false);
            Direction::Backward:
                SetRtngLineSequenceBack(ReqLine."Routing Type", PlanningRtngLine, MaxSeq, 1, false);
        end;
    end;

    procedure Calculate(ReqLine: Record "Requisition Line")
    var
        PlanningRtngLine: Record "Planning Routing Line";
        PlanningRtngLine2: Record "Planning Routing Line";
        CalcScrapFactor: Decimal;
        CalcScrapQty: Decimal;
        ScrapFactorThis: Decimal;
        ScrapQtyThis: Decimal;
    begin
        CalcSequenceBack(ReqLine);
        CalcSequenceForward(ReqLine);

        PlanningRtngLine.SetCurrentKey(
          "Worksheet Template Name",
          "Worksheet Batch Name",
          "Worksheet Line No.",
          "Sequence No.(Backward)");
        PlanningRtngLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", ReqLine."Line No.");
        if PlanningRtngLine.Find('-') then
            repeat
                if PlanningRtngLine."Next Operation No." <> '' then begin
                    PlanningRtngLine2.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                    PlanningRtngLine2.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
                    PlanningRtngLine2.SetRange("Worksheet Line No.", ReqLine."Line No.");
                    PlanningRtngLine2.SetFilter("Operation No.", PlanningRtngLine."Next Operation No.");
                    CalcScrapFactor := 0;
                    CalcScrapQty := 0;
                    if PlanningRtngLine2.Find('-') then
                        repeat
                            ScrapFactorThis :=
                              PlanningRtngLine2."Scrap Factor % (Accumulated)";
                            ScrapQtyThis :=
                              PlanningRtngLine2."Fixed Scrap Qty. (Accum.)";
                            CalcScrapFactor := CalcScrapFactor + ScrapFactorThis;
                            CalcScrapQty := CalcScrapQty + ScrapQtyThis;
                        until PlanningRtngLine2.Next() = 0;
                end;
                if CalcScrapFactor <> 0 then begin
                    if PlanningRtngLine."Scrap Factor %" <> 0 then
                        CalcScrapFactor :=
                          Round((1 + CalcScrapFactor) *
                            (1 + PlanningRtngLine."Scrap Factor %" / 100), UOMMgt.QtyRndPrecision()) - 1;
                end else
                    CalcScrapFactor :=
                      Round(1 + PlanningRtngLine."Scrap Factor %" / 100, UOMMgt.QtyRndPrecision()) - 1;
                CalcScrapQty := CalcScrapQty + PlanningRtngLine."Fixed Scrap Quantity";
                PlanningRtngLine."Fixed Scrap Qty. (Accum.)" := CalcScrapQty;
                PlanningRtngLine."Scrap Factor % (Accumulated)" := CalcScrapFactor;
                PlanningRtngLine.Modify();
            until PlanningRtngLine.Next() = 0;

        PlanningRtngLine.ModifyAll(Recalculate, false);
        Check(ReqLine);
    end;

    local procedure Check(ReqLine: Record "Requisition Line")
    var
        PlanningRtngLine: Record "Planning Routing Line";
        PlanningRtngLine2: Record "Planning Routing Line";
        NoOfProcesses: Integer;
    begin
        PlanningRtngLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", ReqLine."Line No.");

        PlanningRtngLine.SetFilter("Next Operation No.", '%1', '');

        NoOfProcesses := PlanningRtngLine.Count();
        if NoOfProcesses <> 1 then begin
            repeat
                InsertInErrList(PlanningRtngLine);
            until PlanningRtngLine.Next() = 0;
            Error(
              Text002,
              ReqLine."Line No.",
              NoOfProcesses,
              ErrList);
        end;

        PlanningRtngLine.SetFilter("Previous Operation No.", '%1', '');
        PlanningRtngLine.SetRange("Next Operation No.");
        NoOfProcesses := PlanningRtngLine.Count();
        if NoOfProcesses <> 1 then begin
            repeat
                InsertInErrList(PlanningRtngLine);
            until PlanningRtngLine.Next() = 0;
            Error(
              Text003,
              ReqLine."Line No.",
              NoOfProcesses,
              ErrList);
        end;
        PlanningRtngLine.SetRange("Previous Operation No.");

        PlanningRtngLine.SetRange("Sequence No.(Backward)", 0);
        if PlanningRtngLine.Find('-') then begin
            repeat
                InsertInErrList(PlanningRtngLine);
            until PlanningRtngLine.Next() = 0;
            Error(
              Text004,
              ReqLine."Line No.",
              ErrList);
        end;
        PlanningRtngLine.SetRange("Sequence No.(Backward)");

        PlanningRtngLine.SetRange("Sequence No.(Forward)", 0);
        if PlanningRtngLine.Find('-') then begin
            repeat
                InsertInErrList(PlanningRtngLine);
            until PlanningRtngLine.Next() = 0;
            Error(
              NotAllRoutingLineSequencedForwardErr,
              ReqLine."Line No.",
              ErrList);
        end;
        PlanningRtngLine.SetRange("Sequence No.(Forward)");

        PlanningRtngLine.SetCurrentKey(
          "Worksheet Template Name",
          "Worksheet Batch Name",
          "Worksheet Line No.",
          "Sequence No.(Backward)");
        PlanningRtngLine.SetFilter("Previous Operation No.", '<>%1', '');

        if PlanningRtngLine.Find('-') then
            repeat
                PlanningRtngLine2.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                PlanningRtngLine2.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
                PlanningRtngLine2.SetRange("Worksheet Line No.", ReqLine."Line No.");
                PlanningRtngLine2.SetFilter("Operation No.", PlanningRtngLine."Previous Operation No.");
                if PlanningRtngLine2.IsEmpty() then
                    Error(
                      Text006,
                      PlanningRtngLine."Operation No.");
            until PlanningRtngLine.Next() = 0;

        PlanningRtngLine.SetCurrentKey(
          "Worksheet Template Name",
          "Worksheet Batch Name",
          "Worksheet Line No.",
          "Sequence No.(Backward)");

        PlanningRtngLine.SetFilter("Next Operation No.", '<>%1', '');
        PlanningRtngLine.SetRange("Operation No.");

        if PlanningRtngLine.Find('-') then
            repeat
                PlanningRtngLine2.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                PlanningRtngLine2.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
                PlanningRtngLine2.SetRange("Worksheet Line No.", ReqLine."Line No.");
                PlanningRtngLine2.SetFilter("Operation No.", PlanningRtngLine."Next Operation No.");
                if PlanningRtngLine2.IsEmpty() then
                    Error(Text007, PlanningRtngLine."Worksheet Line No.");
            until PlanningRtngLine.Next() = 0;
    end;
}

