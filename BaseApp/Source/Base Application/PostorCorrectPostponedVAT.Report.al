report 11790 "Post or Correct Postponed VAT"
{
    Caption = 'Post or Correct Postponed VAT';
    Permissions = TableData "Sales Cr.Memo Header" = m,
                  TableData "Service Cr.Memo Header" = m;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            var
                ConfirmMsg: Text[250];
            begin
                if SkipReport then
                    CurrReport.Break;

                if VATDate = 0D then
                    Error(Text11805);
                if "Postponed VAT" and CorrectEntries then
                    Error(Text11801);
                if (not "Postponed VAT") and (not CorrectEntries) then
                    Error(Text11802);
                if VATDate < "Posting Date" then
                    Error(Text11804);
                if GenJnlCheckLine.VATDateNotAllowed(VATDate) then
                    Error(Text11806, VATDate);
                if GenJnlCheckLine.DateNotAllowed(VATDate) then
                    Error(Text11807, VATDate);
                GenJnlCheckLine.VATPeriodCheck(VATDate);

                if "Postponed VAT" or "Postponed VAT Realized" then begin
                    TestField("Postponed VAT", not CorrectEntries);
                    TestField("Postponed VAT Realized", CorrectEntries);
                end;

                if CurrReport.UseRequestPage then begin
                    if CorrectEntries then
                        ConfirmMsg := Text26508
                    else
                        ConfirmMsg := Text26507;
                    if not Confirm(ConfirmMsg, true, VATDate) then
                        CurrReport.Skip;
                end;

                HandlePostponedVAT(VATDate, not CorrectEntries);
                Modify;

                if CurrReport.UseRequestPage then
                    Message(Text26500);
            end;

            trigger OnPreDataItem()
            begin
                SkipReport := GetFilter("No.") = '';
                if SkipReport then
                    CurrReport.Break;
            end;
        }
        dataitem("Service Cr.Memo Header"; "Service Cr.Memo Header")
        {
            DataItemTableView = SORTING("No.") ORDER(Ascending);
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            var
                ConfirmMsg: Text[250];
            begin
                if SkipReport then
                    CurrReport.Break;

                if VATDate = 0D then
                    Error(Text11805);
                if "Postponed VAT" and CorrectEntries then
                    Error(Text11801);
                if (not "Postponed VAT") and (not CorrectEntries) then
                    Error(Text11802);
                if VATDate < "Posting Date" then
                    Error(Text11804);
                if GenJnlCheckLine.VATDateNotAllowed(VATDate) then
                    Error(Text11806, VATDate);
                if GenJnlCheckLine.DateNotAllowed(VATDate) then
                    Error(Text11807, VATDate);
                GenJnlCheckLine.VATPeriodCheck(VATDate);

                if "Postponed VAT" or "Postponed VAT Realized" then begin
                    TestField("Postponed VAT", not CorrectEntries);
                    TestField("Postponed VAT Realized", CorrectEntries);
                end;

                if CurrReport.UseRequestPage then begin
                    if CorrectEntries then
                        ConfirmMsg := Text26508
                    else
                        ConfirmMsg := Text26507;
                    if not Confirm(ConfirmMsg, true, VATDate) then
                        CurrReport.Skip;
                end;

                HandlePostponedVAT(VATDate, not CorrectEntries);
                Modify;

                if CurrReport.UseRequestPage then
                    Message(Text26500)
            end;

            trigger OnPreDataItem()
            begin
                SkipReport := GetFilter("No.") = '';
                if SkipReport then
                    CurrReport.Break;
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
                    field(VATDate; VATDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New VAT Date';
                        ToolTip = 'Specifies the VAT date for post realized VAT entries.';
                    }
                    field(CorrectEntries; CorrectEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Correction';
                        ToolTip = 'Specifies this option to enable postponed VAT corrections.';
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

    trigger OnPreReport()
    begin
        if (("Sales Cr.Memo Header".GetFilter("No.") = '') and ("Service Cr.Memo Header".GetFilter("No.") = '')) or
           (("Sales Cr.Memo Header".GetFilter("No.") <> '') and ("Service Cr.Memo Header".GetFilter("No.") <> ''))
        then
            Error(FilterErr)
    end;

    var
        VATDate: Date;
        CorrectEntries: Boolean;
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        SkipReport: Boolean;
        Text11801: Label 'You must post Postponed VAT before correcting.';
        Text11802: Label 'You cannot post Postponed VAT because it has already been posted.';
        Text11804: Label 'The date of claiming back VAT cannot be earlier than the document date.';
        Text11805: Label 'You must specify the VAT date.';
        Text11806: Label '%1 is not within your range of allowed VAT dates.';
        Text11807: Label '%1 is not within your range of allowed posting dates.', Comment = '%1 = VAT Date';
        Text26507: Label 'Do you really want to post Postponed VAT with VAT Date %1?';
        Text26508: Label 'Do you really want to reverse Postponed VAT with VAT Date %1?';
        Text26500: Label 'The Postponed VAT was successfully posted.';
        FilterErr: Label 'Incorrect filter input error.';

    [Scope('OnPrem')]
    procedure InitializeRequest(NewVATDate: Date; NewCorrection: Boolean)
    begin
        VATDate := NewVATDate;
        CorrectEntries := NewCorrection;
    end;
}

