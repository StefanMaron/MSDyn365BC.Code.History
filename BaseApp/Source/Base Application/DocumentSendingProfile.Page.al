page 360 "Document Sending Profile"
{
    Caption = 'Document Sending Profile';
    PageType = Card;
    SourceTable = "Document Sending Profile";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify the document sending method in the system.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document sending format.';
                }
                field(Default; Default)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this document sending method will be used as the default method for all customers.';
                }
            }
            group("Sending Options")
            {
                Caption = 'Sending Options';
                field(Printer; Printer)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if and how the document is printed when you choose the Post and Send button. If you choose the Yes (Prompt for Settings) option, the document is printed according to settings that you must make on the printer setup dialog.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if and how the document is attached as a PDF file to an email to the involved customer when you choose the Post and Send button. If you choose the Yes (Prompt for Settings) option, the document is attached to an email according to settings that you must make in the Send Email window.';
                }
                group(Control15)
                {
                    ShowCaption = false;
                    Visible = "E-Mail" <> "E-Mail"::No;
                    field("E-Mail Attachment"; "E-Mail Attachment")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of file to attach.';

                        trigger OnValidate()
                        begin
                            "E-Mail Format" := GetFormat;
                        end;
                    }
                    group(Control16)
                    {
                        ShowCaption = false;
                        Visible = "E-Mail Attachment" <> "E-Mail Attachment"::PDF;
                        field("E-Mail Format"; "E-Mail Format")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Format';
                            ToolTip = 'Specifies how customers are set up with their preferred method of sending sales documents.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupElectronicFormat("E-Mail Format");
                            end;

                            trigger OnValidate()
                            begin
                                LastFormat := "E-Mail Format";
                            end;
                        }
                    }
                    field("Combine Email Documents"; Rec."Combine Email Documents")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combine PDF Documents';
                        ToolTip = 'Merge selected documents into a single PDF file when you send the documents by email or print them. For example, this reduces the number of documents the recipient must process.';
                    }
                }
                field(Disk; Disk)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specify if the document is saved as a PDF file when you choose the Post and Send button.';

                    trigger OnValidate()
                    begin
                        "Disk Format" := GetFormat;
                    end;
                }
                group(Control17)
                {
                    ShowCaption = false;
                    Visible = (Disk <> Disk::No) AND (Disk <> Disk::PDF);
                    field("Disk Format"; "Disk Format")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Format';
                        ToolTip = 'Specifies how customers are set up with their preferred method of sending sales documents.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupElectronicFormat("Disk Format");
                        end;

                        trigger OnValidate()
                        begin
                            LastFormat := "Disk Format";
                        end;
                    }
                }
                field("Electronic Document"; "Electronic Document")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the document is sent as an electronic document that the customer can import into their system when you choose the Post and Send button. To use this option, you must also fill the Electronic Format field. Alternatively, the file can be saved to disk.';
                    Visible = ElectronicDocumentsVisible;

                    trigger OnValidate()
                    begin
                        "Electronic Format" := GetFormat;
                    end;
                }
                group(Control18)
                {
                    ShowCaption = false;
                    Visible = "Electronic Document" <> "Electronic Document"::No;
                    field("Electronic Format"; "Electronic Format")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Format';
                        ToolTip = 'Specifies which format to use for electronic document sending. You must fill this field if you selected the Silent option in the Electronic Document field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupElectronicFormat("Electronic Format");
                        end;

                        trigger OnValidate()
                        begin
                            LastFormat := "Electronic Format";
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.OnDiscoverElectronicFormat;
        ElectronicDocumentsVisible := not ElectronicDocumentFormat.IsEmpty;
    end;

    var
        LastFormat: Code[20];
        ElectronicDocumentsVisible: Boolean;

    local procedure LookupElectronicFormat(var ElectronicFormat: Code[20])
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ElectronicDocumentFormats: Page "Electronic Document Formats";
    begin
        ElectronicDocumentFormat.SetRange(Usage, Usage);
        ElectronicDocumentFormats.SetTableView(ElectronicDocumentFormat);
        ElectronicDocumentFormats.LookupMode := true;

        if ElectronicDocumentFormats.RunModal = ACTION::LookupOK then begin
            ElectronicDocumentFormats.GetRecord(ElectronicDocumentFormat);
            ElectronicFormat := ElectronicDocumentFormat.Code;
            LastFormat := ElectronicDocumentFormat.Code;
            exit;
        end;

        ElectronicFormat := GetFormat;
    end;

    local procedure GetFormat(): Code[20]
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FindNewFormat: Boolean;
    begin
        FindNewFormat := false;

        if LastFormat = '' then
            FindNewFormat := true
        else begin
            ElectronicDocumentFormat.SetRange(Code, LastFormat);
            ElectronicDocumentFormat.SetRange(Usage, Usage);
            if not ElectronicDocumentFormat.FindFirst then
                FindNewFormat := true;
        end;

        if FindNewFormat then begin
            ElectronicDocumentFormat.SetRange(Code);
            ElectronicDocumentFormat.SetRange(Usage, Usage);
            if not ElectronicDocumentFormat.FindFirst then
                LastFormat := ''
            else
                LastFormat := ElectronicDocumentFormat.Code;
        end;

        exit(LastFormat);
    end;
}

