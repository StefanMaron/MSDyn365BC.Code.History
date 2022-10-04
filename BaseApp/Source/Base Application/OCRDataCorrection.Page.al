page 1272 "OCR Data Correction"
{
    Caption = 'OCR Data Correction';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Incoming Document";

    layout
    {
        area(content)
        {
            group(Control35)
            {
                ShowCaption = false;
                grid(Control2)
                {
                    ShowCaption = false;
                    group(Control16)
                    {
                        ShowCaption = false;
                        field("Vendor Name"; Rec."Vendor Name")
                        {
                            ApplicationArea = Basic, Suite;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the name of the vendor on the incoming document. The field may be filled automatically.';
                        }
                        field("Vendor VAT Registration No."; Rec."Vendor VAT Registration No.")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the VAT registration number of the vendor, if the document contains that number. The field may be filled automatically.';
                        }
                        field("Vendor IBAN"; Rec."Vendor IBAN")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the new value that you want the OCR service to produce for this field going forward.';
                        }
                        field("Vendor Bank Branch No."; Rec."Vendor Bank Branch No.")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the new value that you want the OCR service to produce for this field going forward.';
                        }
                        field("Vendor Bank Account No."; Rec."Vendor Bank Account No.")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the new value that you want the OCR service to produce for this field going forward.';
                        }
                        field("Vendor Phone No."; Rec."Vendor Phone No.")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the new value that you want the OCR service to produce for this field going forward.';
                        }
                        field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the document number of the original document you received from the vendor. You can require the document number for posting, or let it be optional. By default, it''s required, so that this document references the original. Making document numbers optional removes a step from the posting process. For example, if you attach the original invoice as a PDF, you might not need to enter the document number. To specify whether document numbers are required, in the Purchases & Payables Setup window, select or clear the Ext. Doc. No. Mandatory field.';
                        }
                        field("Order No."; Rec."Order No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Order No.';
                            ToolTip = 'Specifies the order number, if the document contains that number. The field may be filled automatically.';
                        }
                        field("Document Date"; Rec."Document Date")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the date that is printed on the incoming document. This is the date when the vendor created the invoice, for example. The field may be filled automatically.';
                        }
                        field("Due Date"; Rec."Due Date")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the date when the vendor document must be paid. The field may be filled automatically.';
                        }
                        field("Currency Code"; Rec."Currency Code")
                        {
                            ApplicationArea = Suite;
                            ToolTip = 'Specifies the currency code, if the document contains that code. The field may be filled automatically.';
                        }
                        field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the amount including VAT for the whole document. The field may be filled automatically.';
                        }
                        field("Amount Excl. VAT"; Rec."Amount Excl. VAT")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the amount excluding VAT for the whole document. The field may be filled automatically.';
                        }
                        field("VAT Amount"; Rec."VAT Amount")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
                        }
                    }
                    group(Control18)
                    {
                        ShowCaption = false;
                        field("TempOriginalIncomingDocument.""Vendor Name"""; TempOriginalIncomingDocument."Vendor Name")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Name';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Vendor VAT Registration No."""; TempOriginalIncomingDocument."Vendor VAT Registration No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor VAT Registration No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Vendor IBAN"""; TempOriginalIncomingDocument."Vendor IBAN")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor IBAN';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Vendor Bank Branch No."""; TempOriginalIncomingDocument."Vendor Bank Branch No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Bank Branch No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Vendor Bank Account No."""; TempOriginalIncomingDocument."Vendor Bank Account No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Bank Account No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Vendor Phone No."""; TempOriginalIncomingDocument."Vendor Phone No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Phone No.';
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Vendor Invoice No."""; TempOriginalIncomingDocument."Vendor Invoice No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Invoice No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Order No."""; TempOriginalIncomingDocument."Order No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Order No.';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Document Date"""; TempOriginalIncomingDocument."Document Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document Date';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Due Date"""; TempOriginalIncomingDocument."Due Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Due Date';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Currency Code"""; TempOriginalIncomingDocument."Currency Code")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Currency Code';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Amount Incl. VAT"""; TempOriginalIncomingDocument."Amount Incl. VAT")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount Incl. VAT';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""Amount Excl. VAT"""; TempOriginalIncomingDocument."Amount Excl. VAT")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Amount Excl. VAT';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                        field("TempOriginalIncomingDocument.""VAT Amount"""; TempOriginalIncomingDocument."VAT Amount")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = "Currency Code";
                            AutoFormatType = 1;
                            Caption = 'VAT Amount';
                            Editable = false;
                            ToolTip = 'Specifies the existing value that the OCR service produces for this field.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Reset OCR Data")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset OCR Data';
                Image = Reuse;
                ToolTip = 'Undo corrections that you have made since you opened the OCR Data Correction window.';

                trigger OnAction()
                begin
                    ResetOriginalOCRData();
                end;
            }
            action("Send OCR Feedback")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send OCR Feedback';
                Image = Undo;
                ToolTip = 'Send the corrections to the OCR service. The corrections will be included PDF or image files that contain the data the next time the service processes.';

                trigger OnAction()
                begin
                    if UploadCorrectedOCRData() then
                        CurrPage.Close();
                end;
            }
            action(ShowFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show File';
                Image = Export;
                ToolTip = 'Open the PDF or image file to see the corrections that you have made.';

                trigger OnAction()
                begin
                    ShowMainAttachment();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Reset OCR Data_Promoted"; "Reset OCR Data")
                {
                }
                actionref("Send OCR Feedback_Promoted"; "Send OCR Feedback")
                {
                }
                actionref(ShowFile_Promoted; ShowFile)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TempOriginalIncomingDocument := Rec;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        "OCR Data Corrected" := true;
        Modify();
        exit(false)
    end;

    var
        TempOriginalIncomingDocument: Record "Incoming Document" temporary;
}

