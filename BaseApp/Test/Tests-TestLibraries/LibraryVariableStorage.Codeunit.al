codeunit 131004 "Library - Variable Storage"
{

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        Variables: array[25] of Variant;
        EndIndex: Integer;
        StartIndex: Integer;
        AssertEmptyErr: Label 'Queue is not empty.';
        AssertFullErr: Label 'Queue is empty.';
        TotalCount: Integer;
        OverflowErr: Label 'Queue overflow.';
        UnderflowErr: Label 'Queue underflow.';
        OutOfBoundsErr: Label 'Index out of bounds.';

    procedure AssertEmpty()
    var
        PreviousCount: Integer;
    begin
        PreviousCount := TotalCount;
        if TotalCount <> 0 then begin
            ClearQueue;
            Assert.AreEqual(0, PreviousCount, AssertEmptyErr);
        end;
    end;

    procedure AssertFull()
    begin
        Assert.AreEqual(MaxLength, TotalCount, AssertFullErr);
    end;

    procedure AssertNotOverflow()
    begin
        Assert.IsFalse(TotalCount + 1 > MaxLength, OverflowErr);
    end;

    procedure AssertNotUnderflow()
    begin
        Assert.IsTrue(TotalCount > 0, UnderflowErr);
    end;

    procedure AssertPeekAvailable(Index: Integer)
    begin
        Assert.IsTrue(Index > 0, OutOfBoundsErr);
        Assert.IsTrue(Index <= TotalCount, OutOfBoundsErr);
    end;

    procedure Clear()
    begin
        // For internal calls we need ClearQueue because Clear is a reserved keyword for CAL.
        ClearQueue;
    end;

    local procedure ClearQueue()
    begin
        StartIndex := 0;
        EndIndex := 0;
        TotalCount := 0;
    end;

    procedure Dequeue(var Variable: Variant)
    begin
        StartIndex := (StartIndex mod MaxLength) + 1;
        AssertNotUnderflow;
        Variable := Variables[StartIndex];
        TotalCount -= 1;
    end;

    procedure Peek(var Variable: Variant; Index: Integer)
    begin
        AssertPeekAvailable(Index);
        Variable := Variables[((StartIndex + (Index - 1)) mod MaxLength) + 1];
    end;

    procedure Enqueue(Variable: Variant)
    begin
        EndIndex := (EndIndex mod MaxLength) + 1;
        AssertNotOverflow;
        Variables[EndIndex] := Variable;
        TotalCount += 1;
    end;

    procedure Length(): Integer
    begin
        exit(TotalCount);
    end;

    procedure MaxLength(): Integer
    begin
        exit(ArrayLen(Variables));
    end;

    procedure DequeueText(): Text
    var
        ExpectedValue: Variant;
    begin
        Dequeue(ExpectedValue);
        exit(Format(ExpectedValue));
    end;

    procedure DequeueDecimal(): Decimal
    var
        ExpectedValue: Variant;
    begin
        Dequeue(ExpectedValue);
        exit(ExpectedValue);
    end;

    procedure DequeueInteger(): Integer
    var
        ExpectedValue: Variant;
    begin
        Dequeue(ExpectedValue);
        exit(ExpectedValue);
    end;

    procedure DequeueDate(): Date
    var
        ExpectedValue: Variant;
    begin
        Dequeue(ExpectedValue);
        exit(ExpectedValue);
    end;

    procedure DequeueDateTime(): DateTime
    var
        ExpectedValue: Variant;
    begin
        Dequeue(ExpectedValue);
        exit(ExpectedValue);
    end;

    procedure DequeueTime(): Time
    var
        ExpectedValue: Variant;
    begin
        Dequeue(ExpectedValue);
        exit(ExpectedValue);
    end;

    procedure DequeueBoolean(): Boolean
    var
        ExpectedValue: Variant;
    begin
        Dequeue(ExpectedValue);
        exit(ExpectedValue);
    end;

    procedure PeekText(Index: Integer): Text
    var
        ExpectedValue: Variant;
    begin
        Peek(ExpectedValue, Index);
        exit(Format(ExpectedValue));
    end;

    procedure PeekDecimal(Index: Integer): Decimal
    var
        ExpectedValue: Variant;
    begin
        Peek(ExpectedValue, Index);
        exit(ExpectedValue);
    end;

    procedure PeekInteger(Index: Integer): Integer
    var
        ExpectedValue: Variant;
    begin
        Peek(ExpectedValue, Index);
        exit(ExpectedValue);
    end;

    procedure PeekDate(Index: Integer): Date
    var
        ExpectedValue: Variant;
    begin
        Peek(ExpectedValue, Index);
        exit(ExpectedValue);
    end;

    procedure PeekTime(Index: Integer): Time
    var
        ExpectedValue: Variant;
    begin
        Peek(ExpectedValue, Index);
        exit(ExpectedValue);
    end;

    procedure PeekBoolean(Index: Integer): Boolean
    var
        ExpectedValue: Variant;
    begin
        Peek(ExpectedValue, Index);
        exit(ExpectedValue);
    end;
}

