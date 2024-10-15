page 315 "VAT Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Entries';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    Permissions = TableData "VAT Entry" = m;
    SourceTable = "VAT Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT entry''s posting date.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number on the VAT entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type that the VAT entry belongs to.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the VAT entry.';
                }
                field(Base; Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount (the amount shown in the Amount field) is calculated from.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT entry in LCY.';
                }
                field("Unrealized Amount"; "Unrealized Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unrealized VAT amount for this line if you use unrealized VAT.';
                    Visible = IsUnrealizedVATEnabled;
                }
                field("Unrealized Base"; "Unrealized Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unrealized base amount if you use unrealized VAT.';
                    Visible = IsUnrealizedVATEnabled;
                }
                field("Remaining Unrealized Amount"; "Remaining Unrealized Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains unrealized in the VAT entry.';
                    Visible = IsUnrealizedVATEnabled;
                }
                field("Remaining Unrealized Base"; "Remaining Unrealized Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of base that remains unrealized in the VAT entry.';
                    Visible = IsUnrealizedVATEnabled;
                }
                field("VAT Difference"; "VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Additional-Currency Base"; "Additional-Currency Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount is calculated from if you post in an additional reporting currency.';
                    Visible = false;
                }
                field("Additional-Currency Amount"; "Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT entry. The amount is in the additional reporting currency.';
                    Visible = false;
                }
                field("Add.-Curr. VAT Difference"; "Add.-Curr. VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies, in the additional reporting currency, the VAT difference that arises when you make a correction to a VAT amount on a sales or purchase document.';
                    Visible = false;
                }
                field("VAT Calculation Type"; "VAT Calculation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';
                }
                field("Bill-to/Pay-to No."; "Bill-to/Pay-to No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bill-to customer or pay-to vendor that the entry is linked to.';
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number of the customer or vendor that the entry is linked to.';
                    Visible = false;
                }
                field("Enterprise No."; "Enterprise No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the enterprise number of the customer or vendor linked to the entry.';
                    Visible = false;
                }
                field("Ship-to/Order Address Code"; "Ship-to/Order Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address code of the ship-to customer or order-from vendor that the entry is linked to.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
                field(Closed; Closed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the VAT entry has been closed by the Calc. and Post VAT Settlement batch job.';
                }
                field("Closed by Entry No."; "Closed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the VAT entry that has closed the entry, if the VAT entry was closed with the Calc. and Post VAT Settlement batch job.';
                }
                field("Internal Ref. No."; "Internal Ref. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the internal reference number for the line.';
                }
                field(Reversed; Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been part of a reverse transaction.';
                    Visible = false;
                }
                field("Reversed by Entry No."; "Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the correcting entry. If the field Specifies a number, the entry cannot be reversed again.';
                    Visible = false;
                }
                field("Reversed Entry No."; "Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
                    Visible = false;
                }
                field("EU Service"; "EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this VAT entry is to be reported as a service in the periodic VAT reports.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                SubPageLink = "Posting Date" = field("Posting Date"), "Document No." = field("Document No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Shift+Ctrl+I';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate.SetDoc("Posting Date", "Document No.");
                    Navigate.Run;
                end;
            }
            action(SetGLAccountNo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set G/L Account No.';
                Image = AdjustEntries;
                ToolTip = 'Fill the G/L Account No. field in VAT entries that are linked to G/L entries.';

                trigger OnAction()
                var
                    VATEntry: Record "VAT Entry";
                    Window: Dialog;
                    BucketIndex: Integer;
                    SizeOfBucket: Integer;
                    LastEntryNo: Integer;
                    NoOfBuckets: Integer;
                begin
                    SizeOfBucket := 1000;

                    if not VATEntry.FindLast() then
                        exit;

                    Window.Open(AdjustTitleMsg + ProgressMsg);

                    LastEntryNo := VATEntry."Entry No.";
                    NoOfBuckets := LastEntryNo DIV SizeOfBucket + 1;

                    for BucketIndex := 1 to NoOfBuckets do begin
                        VATEntry.SetRange("Entry No.", (BucketIndex - 1) * SizeOfBucket, BucketIndex * SizeOfBucket);
                        VATEntry.SetGLAccountNo(false);
                        Commit();
                        Window.Update(2, Round(BucketIndex / NoOfBuckets * 10000, 1));
                    end;

                    Window.Close();
                end;
            }
            group(IncomingDocument)
            {
                Caption = 'Incoming Document';
                Image = Documents;
                action(IncomingDocCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View Incoming Document';
                    Enabled = HasIncomingDocument;
                    Image = ViewOrder;
                    ToolTip = 'View any incoming document records and file attachments that exist for the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        IncomingDocument.ShowCard("Document No.", "Posting Date");
                    end;
                }
                action(SelectIncomingDoc)
                {
                    AccessByPermission = TableData "Incoming Document" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Select Incoming Document';
                    Enabled = NOT HasIncomingDocument;
                    Image = SelectLineToApply;
                    ToolTip = 'Select an incoming document record and file attachment that you want to link to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        IncomingDocument.SelectIncomingDocumentForPostedDocument("Document No.", "Posting Date", RecordId);
                    end;
                }
                action(IncomingDocAttachFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Incoming Document from File';
                    Ellipsis = true;
                    Enabled = NOT HasIncomingDocument;
                    Image = Attach;
                    ToolTip = 'Create an incoming document record by selecting a file to attach, and then link the incoming document record to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocumentAttachment: Record "Incoming Document Attachment";
                    begin
                        IncomingDocumentAttachment.NewAttachmentFromPostedDocument("Document No.", "Posting Date");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        HasIncomingDocument := IncomingDocument.PostedDocExists("Document No.", "Posting Date");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"VAT Entry - Edit", Rec);
        exit(false);
    end;

    trigger OnOpenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if GeneralLedgerSetup.Get then
            IsUnrealizedVATEnabled := GeneralLedgerSetup."Unrealized VAT" or GeneralLedgerSetup."Prepayment Unrealized VAT";
    end;

    var
        Navigate: Page Navigate;
        HasIncomingDocument: Boolean;
        IsUnrealizedVATEnabled: Boolean;
        AdjustTitleMsg: Label 'Adjust G/L account number in VAT entries.\';
        ProgressMsg: Label 'Processed: @2@@@@@@@@@@@@@@@@@\';
}

