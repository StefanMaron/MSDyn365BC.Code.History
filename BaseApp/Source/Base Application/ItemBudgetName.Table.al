table 7132 "Item Budget Name"
{
    Caption = 'Item Budget Name';
    LookupPageID = "Item Budget Names";

    fields
    {
        field(1; "Analysis Area"; Option)
        {
            Caption = 'Analysis Area';
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(5; "Budget Dimension 1 Code"; Code[20])
        {
            Caption = 'Budget Dimension 1 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 1 Code" <> xRec."Budget Dimension 1 Code" then begin
                    if Dim.CheckIfDimUsed("Budget Dimension 1 Code", 17, Name, '', "Analysis Area") then
                        Error(Text000, Dim.GetCheckDimErr);
                    Modify;
                end;
            end;
        }
        field(6; "Budget Dimension 2 Code"; Code[20])
        {
            Caption = 'Budget Dimension 2 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 2 Code" <> xRec."Budget Dimension 2 Code" then begin
                    if Dim.CheckIfDimUsed("Budget Dimension 2 Code", 18, Name, '', "Analysis Area") then
                        Error(Text000, Dim.GetCheckDimErr);
                    Modify;
                end;
            end;
        }
        field(7; "Budget Dimension 3 Code"; Code[20])
        {
            Caption = 'Budget Dimension 3 Code';
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Budget Dimension 3 Code" <> xRec."Budget Dimension 3 Code" then begin
                    if Dim.CheckIfDimUsed("Budget Dimension 3 Code", 19, Name, '', "Analysis Area") then
                        Error(Text000, Dim.GetCheckDimErr);
                    Modify;
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Analysis Area", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewBudgetEntry: Record "Item Analysis View Budg. Entry";
    begin
        ItemBudgetEntry.SetCurrentKey("Analysis Area", "Budget Name");
        ItemBudgetEntry.SetRange("Analysis Area", "Analysis Area");
        ItemBudgetEntry.SetRange("Budget Name", Name);
        ItemBudgetEntry.DeleteAll(true);

        ItemAnalysisViewBudgetEntry.SetRange("Analysis Area", "Analysis Area");
        ItemAnalysisViewBudgetEntry.SetRange("Budget Name", Name);
        ItemAnalysisViewBudgetEntry.DeleteAll();
    end;

    var
        Text000: Label '%1\You cannot use the same dimension twice in the same budget.';
        Dim: Record Dimension;
}

