codeunit 17208 "Create Tax Register PR Entry"
{
    TableNo = "Tax Register PR Entry";

    trigger OnRun()
    begin
    end;

    var
        Text21000900: Label 'Search Table    #4############################\Begin period    #1##########\End period      #2##########\@3@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@';
        TaxDimMgt: Codeunit "Tax Dimension Mgt.";
        Window: Dialog;

    [Scope('OnPrem')]
    procedure CreateRegister(SectionCode: Code[10]; StartDate: Date; EndDate: Date)
    var
        TaxRegPREntry: Record "Tax Register PR Entry";
        PayrollLedgEntry: Record "Payroll Ledger Entry";
        Employee: Record Employee;
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        Total: Integer;
        Processed: Integer;
    begin
        TaxRegMgt.ValidateAbsencePREntriesDate(StartDate, EndDate, SectionCode);

        if not TaxRegPREntry.FindLast then
            TaxRegPREntry."Entry No." := 0;

        Window.Open(Text21000900);
        Window.Update(1, StartDate);
        Window.Update(2, EndDate);

        with PayrollLedgEntry do begin
            Window.Update(4, TableCaption);
            Reset;
            SetCurrentKey("Posting Date");
            SetRange("Posting Date", StartDate, EndDate);
            Total := Count;
            Processed := 0;

            if Find('-') then
                repeat
                    Processed += 1;
                    if (Processed mod 50) = 1 then
                        Window.Update(3, Round((Processed / Total) * 10000, 1));

                    if not Employee.Get("Employee No.") then
                        Employee.Init;
                    TaxRegPREntry.Init;
                    TaxRegPREntry."Section Code" := SectionCode;
                    TaxRegPREntry."Starting Date" := StartDate;
                    TaxRegPREntry."Ending Date" := EndDate;
                    TaxRegPREntry."Posting Date" := "Posting Date";
                    TaxRegPREntry."Ledger Entry No." := "Entry No.";
                    TaxRegPREntry."Employee No." := "Employee No.";
                    TaxRegPREntry."Currency Code" := '';
                    TaxRegPREntry.Amount := "Payroll Amount";
                    TaxRegPREntry."Amount (FCY)" := "Amount (ACY)";
                    TaxRegPREntry."Document Type" := "Document Type";
                    TaxRegPREntry."Document No." := "Document No.";
                    TaxRegPREntry.Description := Description;
                    TaxRegPREntry."Employee Payroll Account No." := "Employee Payroll Account No.";
                    TaxRegPREntry."Org. Unit Code" := "Org. Unit Code";
                    TaxRegPREntry."Payroll Element Type" := "Element Type";
                    TaxRegPREntry."Payroll Element Code" := "Element Code";
                    TaxRegPREntry."Fund Type" := "Fund Type";
                    TaxRegPREntry."Payroll Directory Code" := "Directory Code";
                    TaxRegPREntry."Payroll Element Group" := "Element Group";
                    TaxRegPREntry."Payroll Source" := "Source Pay";
                    if TaxRegPREntry.FieldActive("Employee Statistics Group Code") then
                        TaxRegPREntry."Employee Statistics Group Code" := Employee."Statistics Group Code";
                    if TaxRegPREntry.FieldActive("Employee Category Code") then
                        TaxRegPREntry."Employee Category Code" := Employee."Category Code";
                    if TaxRegPREntry.FieldActive("Payroll Posting Group") then
                        TaxRegPREntry."Payroll Posting Group" := "Posting Group";
                    case true of
                        "Element Type" in ["Element Type"::Wage, "Element Type"::Bonus]:
                            TaxRegPREntry."Payroll Directory Type" := TaxRegPREntry."Payroll Directory Type"::Income;
                        "Element Type" in ["Element Type"::"Tax Deduction", "Element Type"::Deduction]:
                            TaxRegPREntry."Payroll Directory Type" := TaxRegPREntry."Payroll Directory Type"::"Tax Deduction";
                        "Element Type" in ["Element Type"::Funds]:
                            TaxRegPREntry."Payroll Directory Type" := TaxRegPREntry."Payroll Directory Type"::Tax;
                    end;
                    TaxDimMgt.SetLedgEntryDim(SectionCode, "Dimension Set ID");
                    if ValidateWhereUsedRegisterIDs(TaxRegPREntry) then begin
                        TaxRegPREntry."Entry No." += 1;
                        TaxRegPREntry.Insert;
                    end;
                until Next(1) = 0;
        end;

        CreateTaxRegAccumulation(StartDate, EndDate, SectionCode);
    end;

    local procedure CreateTaxRegAccumulation(StartDate: Date; EndDate: Date; SectionCode: Code[10])
    var
        TaxReg: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        TaxRegPREntry: Record "Tax Register PR Entry";
        TaxRegLineSetup: Record "Tax Register Line Setup";
        TempTaxRegTemplate: Record "Tax Register Template" temporary;
        TempGLCorrEntry: Record "G/L Correspondence Entry" temporary;
        TaxRegAccumulation2: Record "Tax Register Accumulation";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        AddValue: Decimal;
        GLCorrFound: Boolean;
    begin
        TaxReg.SetRange("Section Code", SectionCode);
        TaxReg.SetRange("Table ID", DATABASE::"Tax Register PR Entry");
        if not TaxReg.Find('-') then
            exit;

        TempGLCorrEntry.SetCurrentKey("Debit Account No.", "Credit Account No.");
        TempGLCorrEntry.Insert;

        TaxRegAccumulation.Reset;
        if not TaxRegAccumulation.FindLast then
            TaxRegAccumulation."Entry No." := 0;

        TaxRegAccumulation.Reset;
        TaxRegAccumulation.Init;
        TaxRegAccumulation."Section Code" := SectionCode;
        TaxRegAccumulation."Starting Date" := StartDate;
        TaxRegAccumulation."Ending Date" := EndDate;

        TaxRegLineSetup.Reset;
        TaxRegLineSetup.SetRange("Section Code", SectionCode);

        Clear(TaxDimMgt);

        TaxReg.Find('-');
        repeat
            TaxRegLineSetup.SetRange("Tax Register No.", TaxReg."No.");
            if TaxRegLineSetup.Find('-') then begin
                TempTaxRegTemplate.DeleteAll;
                TaxRegTemplate.SetRange("Section Code", SectionCode);
                TaxRegTemplate.SetRange(Code, TaxReg."No.");
                if TaxRegTemplate.Find('-') then
                    repeat
                        TempTaxRegTemplate := TaxRegTemplate;
                        TempTaxRegTemplate.Value := 0;
                        TempTaxRegTemplate.Insert;
                    until TaxRegTemplate.Next = 0;

                TaxRegPREntry.Reset;
                TaxRegPREntry.SetCurrentKey("Section Code", "Ending Date");
                TaxRegPREntry.SetRange("Section Code", SectionCode);
                TaxRegPREntry.SetRange("Ending Date", EndDate);
                TaxRegPREntry.SetFilter("Where Used Register IDs", '*~' + TaxReg."Register ID" + '~*');
                if TaxRegPREntry.Find('-') then
                    repeat
                        TaxDimMgt.SetTaxEntryDim(SectionCode,
                          TaxRegPREntry."Dimension 1 Value Code", TaxRegPREntry."Dimension 2 Value Code",
                          TaxRegPREntry."Dimension 3 Value Code", TaxRegPREntry."Dimension 4 Value Code");
                        TempGLCorrEntry."Debit Account No." := TaxRegPREntry."Employee Payroll Account No.";
                        TempGLCorrEntry.Modify;
                        TaxRegLineSetup.Find('-');
                        repeat
                            GLCorrFound := TaxRegLineSetup."Account No." = '';
                            if not GLCorrFound then begin
                                TempGLCorrEntry.SetFilter("Debit Account No.", TaxRegLineSetup."Account No.");
                                GLCorrFound := TempGLCorrEntry.Find;
                            end;
                            if GLCorrFound then begin
                                TempTaxRegTemplate.SetRange("Link Tax Register No.", TaxRegLineSetup."Tax Register No.");
                                TempTaxRegTemplate.SetFilter("Term Line Code", '%1|%2', '', TaxRegLineSetup."Line Code");
                                if TempTaxRegTemplate.Find('-') then
                                    repeat
                                        GLCorrFound := TempTaxRegTemplate."Term Line Code" = '';
                                        if not GLCorrFound then
                                            GLCorrFound := ValidateSetupFilters(TaxRegPREntry, TaxRegLineSetup, TempTaxRegTemplate)
                                        else
                                            GLCorrFound := ValidateTemplateFilters(TaxRegPREntry, TempTaxRegTemplate);
                                        if GLCorrFound and
                                           TaxDimMgt.ValidateTemplateDimFilters(TempTaxRegTemplate)
                                        then begin
                                            case TempTaxRegTemplate."Sum Field No." of
                                                TaxRegPREntry.FieldNo(Amount):
                                                    AddValue := TaxRegPREntry.Amount;
                                                else
                                                    AddValue := 0;
                                            end;
                                            if AddValue <> 0 then begin
                                                TempTaxRegTemplate.Value += AddValue;
                                                TempTaxRegTemplate.Modify;
                                            end;
                                        end;
                                    until TempTaxRegTemplate.Next(1) = 0;
                            end;
                        until TaxRegLineSetup.Next(1) = 0;
                    until TaxRegPREntry.Next(1) = 0;

                TempTaxRegTemplate.Reset;
                if TempTaxRegTemplate.Find('-') then
                    repeat
                        TaxRegAccumulation."Report Line Code" := TempTaxRegTemplate."Report Line Code";
                        TaxRegAccumulation."Template Line Code" := TempTaxRegTemplate."Line Code";
                        TaxRegAccumulation."Section Code" := TempTaxRegTemplate."Section Code";
                        TaxRegAccumulation."Tax Register No." := TempTaxRegTemplate.Code;
                        TaxRegAccumulation.Indentation := TempTaxRegTemplate.Indentation;
                        TaxRegAccumulation.Bold := TempTaxRegTemplate.Bold;
                        TaxRegAccumulation.Description := TempTaxRegTemplate.Description;
                        TaxRegAccumulation.Amount := TempTaxRegTemplate.Value;
                        TaxRegAccumulation."Amount Period" := TempTaxRegTemplate.Value;
                        TaxRegAccumulation."Template Line No." := TempTaxRegTemplate."Line No.";
                        TaxRegAccumulation."Amount Date Filter" :=
                          TaxRegTermMgt.CalcIntervalDate(
                            TaxRegAccumulation."Starting Date",
                            TaxRegAccumulation."Ending Date",
                            TempTaxRegTemplate.Period);
                        TaxRegAccumulation.Amount := TaxRegAccumulation."Amount Period";
                        TaxRegAccumulation."Entry No." += 1;
                        TaxRegAccumulation.Insert;
                        if TempTaxRegTemplate.Period <> '' then begin
                            TaxRegAccumulation2 := TaxRegAccumulation;
                            TaxRegAccumulation2.Reset;
                            TaxRegAccumulation2.SetCurrentKey(
                              "Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
                            TaxRegAccumulation2.SetRange("Section Code", TaxRegAccumulation."Section Code");
                            TaxRegAccumulation2.SetRange("Tax Register No.", TaxRegAccumulation."Tax Register No.");
                            TaxRegAccumulation2.SetRange("Template Line No.", TaxRegAccumulation."Template Line No.");
                            TaxRegAccumulation2.SetFilter("Starting Date", TaxRegAccumulation."Amount Date Filter");
                            TaxRegAccumulation2.SetFilter("Ending Date", TaxRegAccumulation."Amount Date Filter");
                            TaxRegAccumulation2.CalcSums("Amount Period");
                            TaxRegAccumulation.Amount := TaxRegAccumulation2."Amount Period";
                            TaxRegAccumulation.Modify;
                        end;
                    until TempTaxRegTemplate.Next = 0;
            end;
        until TaxReg.Next(1) = 0;
        TempTaxRegTemplate.DeleteAll;
    end;

    local procedure ValidateTemplateFilters(TaxRegPREntry: Record "Tax Register PR Entry"; TempTaxRegTemplate: Record "Tax Register Template"): Boolean
    var
        CheckBuffer: Record "Drop Shpt. Post. Buffer" temporary;
    begin
        with CheckBuffer do begin
            if TempTaxRegTemplate."Org. Unit Code" <> '' then begin
                "Order No." := TaxRegPREntry."Org. Unit Code";
                Insert;
                SetFilter("Order No.", TempTaxRegTemplate."Org. Unit Code");
                if not Find then
                    exit(false);
                Delete;
            end;

            if TempTaxRegTemplate."Element Type Totaling" <> '' then begin
                Reset;
                "Order Line No." := TaxRegPREntry."Payroll Element Type";
                SetFilter("Order Line No.", TempTaxRegTemplate."Element Type Totaling");
                Insert;
                if not Find then
                    exit(false);
                Delete;
            end;

            if TempTaxRegTemplate."Payroll Source Totaling" <> '' then begin
                Reset;
                "Order Line No." := TaxRegPREntry."Payroll Source";
                SetFilter("Order Line No.", TempTaxRegTemplate."Payroll Source Totaling");
                Insert;
                if not Find then
                    exit(false);
                Delete;
            end;
        end;
        exit(true);
    end;

    local procedure ValidateWhereUsedRegisterIDs(var TaxRegPREntry: Record "Tax Register PR Entry"): Boolean
    var
        TaxReg: Record "Tax Register";
        TaxRegLineSetup: Record "Tax Register Line Setup";
        TempTaxRegTemplate: Record "Tax Register Template";
    begin
        TempTaxRegTemplate.Init;
        with TaxRegPREntry do begin
            TaxReg.SetRange("Section Code", "Section Code");
            TaxReg.SetRange("Table ID", DATABASE::"Tax Register PR Entry");
            if TaxReg.Find('-') then
                repeat
                    TaxRegLineSetup.SetRange("Section Code", "Section Code");
                    TaxRegLineSetup.SetRange("Tax Register No.", TaxReg."No.");
                    if TaxRegLineSetup.Find('-') then
                        repeat
                            if TaxDimMgt.ValidateSetupDimFilters(TaxRegLineSetup) then
                                if ValidateSetupFilters(TaxRegPREntry, TaxRegLineSetup, TempTaxRegTemplate) then begin
                                    if "Where Used Register IDs" = '' then
                                        "Where Used Register IDs" := '~';
                                    if StrPos("Where Used Register IDs", '~' + TaxReg."Register ID" + '~') = 0 then
                                        "Where Used Register IDs" :=
                                          StrSubstNo('%1%2~', "Where Used Register IDs", TaxReg."Register ID");
                                end;
                        until TaxRegLineSetup.Next(1) = 0;
                until TaxReg.Next(1) = 0;
            exit("Where Used Register IDs" <> '');
        end;
    end;

    local procedure ValidateSetupFilters(TaxRegPREntry: Record "Tax Register PR Entry"; TaxRegLineSetup: Record "Tax Register Line Setup"; TempTaxRegTemplate: Record "Tax Register Template") InsertEntry: Boolean
    var
        CheckBuffer: Record "Drop Shpt. Post. Buffer" temporary;
        LookupMgt: Codeunit "Lookup Management";
        Totaling: Text[250];
    begin
        InsertEntry := true;
        with TaxRegPREntry do begin
            if TaxRegLineSetup."Account No." <> '' then begin
                CheckBuffer."Order No." := "Employee Payroll Account No.";
                CheckBuffer.SetFilter("Order No.", TaxRegLineSetup."Account No.");
                CheckBuffer.Insert;
                InsertEntry := CheckBuffer.Find;
                CheckBuffer.Delete;
            end;

            if FieldActive("Employee Statistics Group Code") and
               TaxRegLineSetup.FieldActive("Employee Statistics Group Code")
            then
                if InsertEntry and (TaxRegLineSetup."Employee Statistics Group Code" <> '') then begin
                    CheckBuffer."Order No." := "Employee Statistics Group Code";
                    CheckBuffer.SetFilter("Order No.", TaxRegLineSetup."Employee Statistics Group Code");
                    CheckBuffer.Insert;
                    InsertEntry := CheckBuffer.Find;
                    CheckBuffer.Delete;
                end;

            if FieldActive("Employee Category Code") and
               TaxRegLineSetup.FieldActive("Employee Category Code")
            then
                if InsertEntry and (TaxRegLineSetup."Employee Category Code" <> '') then begin
                    CheckBuffer."Order No." := "Employee Category Code";
                    CheckBuffer.SetFilter("Order No.", TaxRegLineSetup."Employee Category Code");
                    CheckBuffer.Insert;
                    InsertEntry := CheckBuffer.Find;
                    CheckBuffer.Delete;
                end;

            if FieldActive("Payroll Posting Group") and
               TaxRegLineSetup.FieldActive("Payroll Posting Group")
            then
                if InsertEntry and (TaxRegLineSetup."Payroll Posting Group" <> '') then begin
                    CheckBuffer."Order No." := "Payroll Posting Group";
                    CheckBuffer.SetFilter("Order No.", TaxRegLineSetup."Payroll Posting Group");
                    CheckBuffer.Insert;
                    InsertEntry := CheckBuffer.Find;
                    CheckBuffer.Delete;
                end;

            if InsertEntry then
                LookupMgt.MergeOptionLists(
                  DATABASE::"Tax Register Line Setup", TaxRegLineSetup.FieldNo("Element Type Filter"),
                  TaxRegLineSetup."Element Type Totaling", TempTaxRegTemplate."Element Type Totaling", Totaling);

            if InsertEntry and (Totaling <> '') then begin
                CheckBuffer.Reset;
                CheckBuffer."Order Line No." := "Payroll Element Type";
                CheckBuffer.SetFilter("Order Line No.", Totaling);
                CheckBuffer.Insert;
                InsertEntry := CheckBuffer.Find;
                CheckBuffer.Delete;
            end;

            if InsertEntry then
                LookupMgt.MergeOptionLists(
                  DATABASE::"Tax Register Line Setup", TaxRegLineSetup.FieldNo("Payroll Source"),
                  TaxRegLineSetup."Payroll Source Totaling", TempTaxRegTemplate."Payroll Source Totaling", Totaling);

            if InsertEntry and (Totaling <> '') then begin
                CheckBuffer.Reset;
                CheckBuffer."Order Line No." := "Payroll Source";
                CheckBuffer.SetFilter("Order Line No.", Totaling);
                CheckBuffer.Insert;
                InsertEntry := CheckBuffer.Find;
                CheckBuffer.Delete;
            end;
        end;
    end;
}

