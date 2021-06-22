table 95 "G/L Budget Name"
{
    Caption = 'G/L Budget Name';
    LookupPageID = "G/L Budget Names";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(3; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(4; "Budget Dimension 1 Code"; Code[20])
        {
            Caption = 'Budget Dimension 1 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 1 Code" <> xRec."Budget Dimension 1 Code" then
                    if Dim.CheckIfDimUsed("Budget Dimension 1 Code", 9, Name, '', 0) then
                        Error(Text000, Dim.GetCheckDimErr);
            end;
        }
        field(5; "Budget Dimension 2 Code"; Code[20])
        {
            Caption = 'Budget Dimension 2 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 2 Code" <> xRec."Budget Dimension 2 Code" then
                    if Dim.CheckIfDimUsed("Budget Dimension 2 Code", 10, Name, '', 0) then
                        Error(Text000, Dim.GetCheckDimErr);
            end;
        }
        field(6; "Budget Dimension 3 Code"; Code[20])
        {
            Caption = 'Budget Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 3 Code" <> xRec."Budget Dimension 3 Code" then
                    if Dim.CheckIfDimUsed("Budget Dimension 3 Code", 11, Name, '', 0) then
                        Error(Text000, Dim.GetCheckDimErr);
            end;
        }
        field(7; "Budget Dimension 4 Code"; Code[20])
        {
            Caption = 'Budget Dimension 4 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 4 Code" <> xRec."Budget Dimension 4 Code" then
                    if Dim.CheckIfDimUsed("Budget Dimension 4 Code", 12, Name, '', 0) then
                        Error(Text000, Dim.GetCheckDimErr);
            end;
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        AnalysisViewBudgetEntry: Record "Analysis View Budget Entry";
    begin
        GLBudgetEntry.SetCurrentKey("Budget Name");
        GLBudgetEntry.SetRange("Budget Name", Name);
        GLBudgetEntry.DeleteAll(true);

        AnalysisViewBudgetEntry.SetRange("Budget Name", Name);
        AnalysisViewBudgetEntry.DeleteAll(true);
    end;

    trigger OnModify()
    begin
        if ("Budget Dimension 1 Code" <> xRec."Budget Dimension 1 Code") or
           ("Budget Dimension 2 Code" <> xRec."Budget Dimension 2 Code") or
           ("Budget Dimension 3 Code" <> xRec."Budget Dimension 3 Code") or
           ("Budget Dimension 4 Code" <> xRec."Budget Dimension 4 Code")
        then
            UpdateGLBudgetEntryDim;
    end;

    var
        Text000: Label '%1\You cannot use the same dimension twice in the same budget.';
        Text001: Label 'Updating budget entries @1@@@@@@@@@@@@@@@@@@';
        Dim: Record Dimension;
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;

    local procedure UpdateGLBudgetEntryDim()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        Window: Dialog;
        TotalCount: Integer;
        i: Integer;
        T0: Time;
    begin
        GLBudgetEntry.SetCurrentKey("Budget Name");
        GLBudgetEntry.SetRange("Budget Name", Name);
        GLBudgetEntry.SetFilter("Dimension Set ID", '<>%1', 0);
        TotalCount := Count;
        Window.Open(Text001);
        T0 := Time;
        GLBudgetEntry.LockTable();
        if GLBudgetEntry.FindSet then
            repeat
                i := i + 1;
                if Time > T0 + 750 then begin
                    Window.Update(1, 10000 * i div TotalCount);
                    T0 := Time;
                end;
                GLBudgetEntry."Budget Dimension 1 Code" := GetDimValCode(GLBudgetEntry."Dimension Set ID", "Budget Dimension 1 Code");
                GLBudgetEntry."Budget Dimension 2 Code" := GetDimValCode(GLBudgetEntry."Dimension Set ID", "Budget Dimension 2 Code");
                GLBudgetEntry."Budget Dimension 3 Code" := GetDimValCode(GLBudgetEntry."Dimension Set ID", "Budget Dimension 3 Code");
                GLBudgetEntry."Budget Dimension 4 Code" := GetDimValCode(GLBudgetEntry."Dimension Set ID", "Budget Dimension 4 Code");
                GLBudgetEntry.Modify();
            until GLBudgetEntry.Next = 0;
        Window.Close;
    end;

    local procedure GetDimValCode(DimSetID: Integer; DimCode: Code[20]): Code[20]
    begin
        if DimCode = '' then
            exit('');
        if TempDimSetEntry.Get(DimSetID, DimCode) then
            exit(TempDimSetEntry."Dimension Value Code");
        if DimSetEntry.Get(DimSetID, DimCode) then
            TempDimSetEntry := DimSetEntry
        else begin
            TempDimSetEntry.Init();
            TempDimSetEntry."Dimension Set ID" := DimSetID;
            TempDimSetEntry."Dimension Code" := DimCode;
        end;
        TempDimSetEntry.Insert();
        exit(TempDimSetEntry."Dimension Value Code")
    end;
}

