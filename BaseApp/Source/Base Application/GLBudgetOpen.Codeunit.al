codeunit 7 "GLBudget-Open"
{
    TableNo = "G/L Account";

    trigger OnRun()
    begin
        if GetFilter("Budget Filter") = '' then
            SearchForName := true
        else begin
            GLBudgetName.SetFilter(Name, GetFilter("Budget Filter"));
            SearchForName := not GLBudgetName.FindFirst;
            GLBudgetName.SetRange(Name);
        end;
        if SearchForName then begin
            if not GLBudgetName.FindFirst then begin
                GLBudgetName.Init();
                GLBudgetName.Name := Text000;
                GLBudgetName.Description := Text001;
                GLBudgetName.Insert();
            end;
            SetFilter("Budget Filter", GLBudgetName.Name);
        end;
    end;

    var
        Text000: Label 'DEFAULT';
        Text001: Label 'Default Budget';
        GLBudgetName: Record "G/L Budget Name";
        SearchForName: Boolean;

    procedure SetupFiltersOnGLAccBudgetPage(var GlobalDim1Filter: Text; var GlobalDim2Filter: Text; var GlobalDim1FilterEnable: Boolean; var GlobalDim2FilterEnable: Boolean; var PeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period"; var DateFilter: Text; var GLAccount: Record "G/L Account")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        with GLAccount do begin
            GlobalDim1Filter := GetFilter("Global Dimension 1 Filter");
            GlobalDim2Filter := GetFilter("Global Dimension 2 Filter");
            GLSetup.Get();
            GlobalDim1FilterEnable :=
              (GLSetup."Global Dimension 1 Code" <> '') and
              (GlobalDim1Filter = '');
            GlobalDim2FilterEnable :=
              (GLSetup."Global Dimension 2 Code" <> '') and
              (GlobalDim2Filter = '');
            PeriodType := PeriodType::Month;
            DateFilter := GetFilter("Date Filter");
            if DateFilter = '' then begin
                DateFilter := Format(CalcDate('<-CY>', Today)) + '..' + Format(CalcDate('<CY>', Today));
                SetFilter("Date Filter", DateFilter);
            end;
        end;
    end;
}

