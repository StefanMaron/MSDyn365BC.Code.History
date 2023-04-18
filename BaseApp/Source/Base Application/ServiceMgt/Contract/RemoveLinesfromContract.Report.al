report 6034 "Remove Lines from Contract"
{
    ApplicationArea = Service;
    Caption = 'Remove Service Contract Lines';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Service Contract Line"; "Service Contract Line")
        {
            DataItemTableView = SORTING("Contract Type", "Contract No.", Credited, "New Line") WHERE("Contract Type" = CONST(Contract), "Contract Status" = CONST(Signed), "New Line" = CONST(false));
            RequestFilterFields = "Contract No.", "Service Item No.";

            trigger OnAfterGetRecord()
            begin
                j := j + 1;
                Window.Update(1, Round(j / i * 10000, 1));

                if LastContractNo <> "Contract No." then begin
                    LastContractNo := "Contract No.";
                    ServContract.Get("Contract Type", "Contract No.");
                    FiledServContract.FileContract(ServContract);
                    if ServContract."Automatic Credit Memos" and
                       ("Credit Memo Date" > 0D) and
                       CreditMemoBaseExists()
                    then
                        CreditMemoCreated := CreditMemoCreated + 1;
                end;
                SuspendStatusCheck(true);
                Delete(true);

                LinesRemoved := LinesRemoved + 1;
            end;

            trigger OnPreDataItem()
            begin
                if DeleteLines = DeleteLines::"Print Only" then begin
                    Clear(ExpiredContractLinesTest);
                    ExpiredContractLinesTest.InitVariables(DelToDate, ReasonCode);
                    ExpiredContractLinesTest.SetTableView("Service Contract Line");
                    ExpiredContractLinesTest.RunModal();
                    CurrReport.Break();
                end;

                if DelToDate = 0D then
                    Error(Text002);
                ServMgtSetup.Get();
                if ServMgtSetup."Use Contract Cancel Reason" then
                    if ReasonCode = '' then
                        Error(Text003);
                SetFilter("Contract Expiration Date", '<>%1&<=%2', 0D, DelToDate);

                Window.Open(
                  Text004 +
                  '@1@@@@@@@@@@@@@@@@@@@@@@@@@@@');
                i := Count;
                j := 0;
                LinesRemoved := 0;
                LastContractNo := '';
                CreditMemoCreated := 0;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DelToDate; DelToDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Remove Lines to';
                        ToolTip = 'Specifies the date up to which you want to remove contract lines. The batch job includes contract lines with contract expiration dates on or before this date.';
                    }
                    field(ReasonCode; ReasonCode)
                    {
                        ApplicationArea = Service;
                        Caption = 'Reason Code';
                        ToolTip = 'Specifies the reason code for the removal of lines from the contract. To see the existing reason codes, choose the Filter field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            ReasonCode2.Reset();
                            ReasonCode2.Code := ReasonCode;
                            if PAGE.RunModal(0, ReasonCode2) = ACTION::LookupOK then begin
                                ReasonCode2.Get(ReasonCode2.Code);
                                ReasonCode := ReasonCode2.Code;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            ReasonCode2.Get(ReasonCode);
                        end;
                    }
                    field("Reason Code"; ReasonCode2.Description)
                    {
                        ApplicationArea = Service;
                        Caption = 'Reason Code Description';
                        Editable = false;
                        ToolTip = 'Specifies a description of the Reason Code.';
                    }
                    field(DeleteLines; DeleteLines)
                    {
                        ApplicationArea = Service;
                        Caption = 'Action';
                        OptionCaption = 'Delete Lines,Print Only';
                        ToolTip = 'Specifies the desired action relating to removing expired contract lines from service contracts.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        DelToDate := WorkDate();
        ServMgtSetup.Get();
    end;

    trigger OnPostReport()
    begin
        if DeleteLines = DeleteLines::"Delete Lines" then
            if LinesRemoved > 1 then
                Message(Text000, LinesRemoved)
            else
                Message(Text001, LinesRemoved);

        if CreditMemoCreated = 1 then
            Message(Text006);

        if CreditMemoCreated > 1 then
            Message(Text007);
        CreateCreditfromContractLines.InitVariables();
    end;

    trigger OnPreReport()
    begin
        CreateCreditfromContractLines.InitVariables();
    end;

    var
        Text000: Label '%1 contract lines were removed.';
        Text001: Label '%1 contract line was removed.';
        Text002: Label 'You must fill in the Remove Lines to field.';
        Text003: Label 'You must fill in the Reason Code field.';
        Text004: Label 'Removing contract lines... \\';
        ServMgtSetup: Record "Service Mgt. Setup";
        ServContract: Record "Service Contract Header";
        FiledServContract: Record "Filed Service Contract Header";
        ReasonCode2: Record "Reason Code";
        ExpiredContractLinesTest: Report "Expired Contract Lines - Test";
        CreateCreditfromContractLines: Codeunit CreateCreditfromContractLines;
        Window: Dialog;
        i: Integer;
        j: Integer;
        LinesRemoved: Integer;
        DelToDate: Date;
        DeleteLines: Option "Delete Lines","Print Only";
        ReasonCode: Code[10];
        LastContractNo: Code[20];
        Text006: Label 'A credit memo was created/updated.';
        CreditMemoCreated: Integer;
        Text007: Label 'Credit memos were created/updated.';
}

