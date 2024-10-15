page 11416 "Elec. Tax Decl. Response Msgs."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Elec. Tax Decl. Response Msgs.';
    DataCaptionFields = "Declaration No.";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Elec. Tax Decl. Response Msg.";
    SourceTableView = SORTING("No.")
                      ORDER(Ascending);
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number that is assigned to the tax declaration response message as a unique identifier.';
                }
                field("Status Code"; "Status Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the status codes provided by the Dutch government.';
                }
                field(Subject; Subject)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the subject of the response message.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Processing Status';
                    Editable = false;
                    ToolTip = 'Specifies the status of the response message.';
                }
                field("Date Sent"; "Date Sent")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date';
                    Editable = false;
                    ToolTip = 'Specifies the date when the response message was sent by the tax authorities.';
                }
                field("Status Description"; "Status Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the status code, associated with the submission of an electronic tax declaration.';
                }
                field(Message; Message.HasValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Message';
                    ToolTip = 'Specifies the message that was sent.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ReceiveResponseMessages)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receive Response Messages';
                    Ellipsis = true;
                    Image = ReturnRelated;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'import the response messages from the tax authorities and store them in the database. The function will get the response messages from the IMAP4 server that you have defined in the Elec. Tax Declaration Setup window.';

                    trigger OnAction()
                    var
                        ElecTaxDeclHeader: Record "Elec. Tax Declaration Header";
                        EnvironmentInfo: Codeunit "Environment Information";
                    begin
                        ElecTaxDeclHeader.SetFilter("Declaration Type", GetFilter("Declaration Type"));
                        ElecTaxDeclHeader.SetFilter("No.", GetFilter("Declaration No."));

                        REPORT.RunModal(REPORT::"Receive Response Messages", EnvironmentInfo.IsSaaS, false, ElecTaxDeclHeader);
                    end;
                }
                action(ProcessResponseMessages)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Process Response Messages';
                    Ellipsis = true;
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Process the received response messages from the tax authorities. This will link the response message to the related electronic tax declaration and update it.';

                    trigger OnAction()
                    var
                        ElecTaxDeclResponseMsg: Record "Elec. Tax Decl. Response Msg.";
                    begin
                        ElecTaxDeclResponseMsg.SetFilter("Declaration Type", GetFilter("Declaration Type"));
                        ElecTaxDeclResponseMsg.SetFilter("Declaration No.", GetFilter("Declaration No."));

                        REPORT.RunModal(REPORT::"Process Response Messages", false, false, ElecTaxDeclResponseMsg);
                    end;
                }
                separator(Action1000020)
                {
                }
                action("E&xport Response Message")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport Response Message';
                    Ellipsis = true;
                    Image = ExportMessage;
                    ToolTip = 'View the content of the message or attachment by export the file to a folder. ';

                    trigger OnAction()
                    begin
                        CalcFields(Message);
                        if Message.HasValue then begin
                            TempBlob.FromRecord(Rec, FieldNo(Message));
                            RBAutoMgt.BLOBExport(TempBlob, '*.*', true);
                        end;
                    end;
                }
            }
        }
    }

    var
        TempBlob: Codeunit "Temp Blob";
        RBAutoMgt: Codeunit "File Management";
}

