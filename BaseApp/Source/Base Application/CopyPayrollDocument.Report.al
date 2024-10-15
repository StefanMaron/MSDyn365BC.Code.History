report 17412 "Copy Payroll Document"
{
    Caption = 'Copy Payroll Document';
    ProcessingOnly = true;

    dataset
    {
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
                    field(DocumentTypeTextBox; DocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Type';
                        OptionCaption = 'Payroll Document,Posted Payroll Document';
                        ToolTip = 'Specifies the type of the related document.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                            ValidateDocNo;
                        end;
                    }
                    field(DocumentNoTextBox; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo;
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo;
                        end;
                    }
                    field("FromPayrollDoc.""Employee No."""; FromPayrollDoc."Employee No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Employee No.';
                        Editable = false;
                    }
                    field("FromPayrollDoc.""Posting Date"""; FromPayrollDoc."Posting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        Editable = false;
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';
                    }
                    field(IncludeHeaderCheckBox; IncludeHeader)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you want to copy information from the document header you are copying.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DocNo <> '' then begin
                case DocType of
                    DocType::"Payroll Document":
                        if FromPayrollDoc.Get(DocNo) then
                            ;
                    DocType::"Posted Payroll Document":
                        if FromPostedPayrollDoc.Get(DocNo) then
                            FromPayrollDoc.TransferFields(FromPostedPayrollDoc);
                end;
                if FromPayrollDoc."No." = '' then
                    DocNo := '';
            end;
            ValidateDocNo;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CopyPayrollDocMgt.SetProperties(IncludeHeader, false);
        CopyPayrollDocMgt.CopyPayrollDoc(DocType, DocNo, PayrollDoc);
    end;

    var
        PayrollDoc: Record "Payroll Document";
        FromPayrollDoc: Record "Payroll Document";
        FromPostedPayrollDoc: Record "Posted Payroll Document";
        CopyPayrollDocMgt: Codeunit "Copy Payroll Document Mgt.";
        DocNo: Code[20];
        DocType: Option "Payroll Document","Posted Payroll Document";
        IncludeHeader: Boolean;

    local procedure ValidateDocNo()
    begin
        if DocNo = '' then
            FromPayrollDoc.Init
        else
            if DocNo <> FromPayrollDoc."No." then begin
                FromPayrollDoc.Init;
                case DocType of
                    DocType::"Payroll Document":
                        FromPayrollDoc.Get(DocNo);
                    DocType::"Posted Payroll Document":
                        begin
                            FromPostedPayrollDoc.Get(DocNo);
                            FromPayrollDoc.TransferFields(FromPostedPayrollDoc);
                        end;
                end;
            end;
        FromPayrollDoc."No." := '';
    end;

    local procedure LookupDocNo()
    begin
        case DocType of
            DocType::"Payroll Document":
                begin
                    FromPayrollDoc."No." := DocNo;
                    if (DocNo = '') and (PayrollDoc."Employee No." <> '') then
                        if FromPayrollDoc.SetCurrentKey("Employee No.") then begin
                            FromPayrollDoc.FilterGroup(2);
                            FromPayrollDoc.SetRange("Employee No.", PayrollDoc."Employee No.");
                            FromPayrollDoc.FilterGroup(0);
                            FromPayrollDoc."Employee No." := PayrollDoc."Employee No.";
                            if FromPayrollDoc.Find('=><') then;
                        end;
                    if PAGE.RunModal(0, FromPayrollDoc) = ACTION::LookupOK then
                        DocNo := FromPayrollDoc."No.";
                end;
            DocType::"Posted Payroll Document":
                begin
                    FromPostedPayrollDoc."No." := DocNo;
                    if (DocNo = '') and (PayrollDoc."Employee No." <> '') then
                        if FromPostedPayrollDoc.SetCurrentKey("Employee No.") then begin
                            FromPostedPayrollDoc.FilterGroup(2);
                            FromPostedPayrollDoc.SetRange("Employee No.", PayrollDoc."Employee No.");
                            FromPostedPayrollDoc.FilterGroup(0);
                            FromPostedPayrollDoc."Employee No." := PayrollDoc."Employee No.";
                            if FromPostedPayrollDoc.Find('=><') then;
                        end;
                    if PAGE.RunModal(0, FromPostedPayrollDoc) = ACTION::LookupOK then
                        DocNo := FromPostedPayrollDoc."No.";
                end;
        end;
        ValidateDocNo;
    end;

    [Scope('OnPrem')]
    procedure SetPayrollDoc(var NewPayrollDoc: Record "Payroll Document")
    begin
        NewPayrollDoc.TestField("No.");
        NewPayrollDoc.TestField("Employee No.");
        PayrollDoc := NewPayrollDoc;
    end;
}

