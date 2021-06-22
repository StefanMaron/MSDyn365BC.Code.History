page 5920 "Service Document Log"
{
    ApplicationArea = Service;
    Caption = 'Service Document Log';
    DataCaptionExpression = GetCaptionHeader;
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Service Document Log";
    SourceTableView = SORTING("Change Date", "Change Time")
                      ORDER(Descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service document that underwent changes.';
                    Visible = DocumentTypeVisible;
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service document that has undergone changes.';
                    Visible = DocumentNoVisible;
                }
                field("Service Item Line No."; "Service Item Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item line, if the event is linked to a service item line.';
                    Visible = false;
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field("ServLogMgt.ServOrderEventDescription(""Event No."")"; ServLogMgt.ServOrderEventDescription("Event No."))
                {
                    ApplicationArea = Service;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the event that occurred to a particular service document.';
                }
                field(After; After)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contents of the modified field after the event takes place.';
                }
                field(Before; Before)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contents of the modified field before the event takes place.';
                }
                field("Change Date"; "Change Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the event.';
                }
                field("Change Time"; "Change Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time of the event.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
            }
        }
        area(factboxes)
        {
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Delete Service Document Log")
                {
                    ApplicationArea = Service;
                    Caption = '&Delete Service Document Log';
                    Ellipsis = true;
                    Image = Delete;
                    ToolTip = 'Delete the automatically generated service document log entries, for example, the unnecessary or outdated ones.';

                    trigger OnAction()
                    var
                        ServOrderLog: Record "Service Document Log";
                        DeleteServOrderLog: Report "Delete Service Document Log";
                    begin
                        ServOrderLog.SetRange("Document Type", "Document Type");
                        ServOrderLog.SetRange("Document No.", "Document No.");
                        DeleteServOrderLog.SetTableView(ServOrderLog);
                        DeleteServOrderLog.RunModal;

                        if DeleteServOrderLog.GetOnPostReportStatus then begin
                            ServOrderLog.Reset();
                            DeleteServOrderLog.GetServDocLog(ServOrderLog);
                            CopyFilters(ServOrderLog);
                            DeleteAll();
                            Reset;
                            SetCurrentKey("Change Date", "Change Time");
                            Ascending(false);
                        end;
                    end;
                }
            }
            action("&Show")
            {
                ApplicationArea = Service;
                Caption = '&Show';
                Image = View;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'View the log details.';

                trigger OnAction()
                var
                    ServShptHeader: Record "Service Shipment Header";
                    ServInvHeader: Record "Service Invoice Header";
                    ServCrMemoHeader: Record "Service Cr.Memo Header";
                    PageManagement: Codeunit "Page Management";
                    isError: Boolean;
                begin
                    if "Document Type" in
                       ["Document Type"::Order, "Document Type"::Quote,
                        "Document Type"::Invoice, "Document Type"::"Credit Memo"]
                    then
                        if ServOrderHeaderRec.Get("Document Type", "Document No.") then begin
                            isError := false;
                            PageManagement.PageRun(ServOrderHeaderRec);
                        end else
                            isError := true
                    else begin // posted documents
                        isError := true;
                        case "Document Type" of
                            "Document Type"::Shipment:
                                if ServShptHeader.Get("Document No.") then begin
                                    isError := false;
                                    PAGE.Run(PAGE::"Posted Service Shipment", ServShptHeader);
                                end;
                            "Document Type"::"Posted Invoice":
                                if ServInvHeader.Get("Document No.") then begin
                                    isError := false;
                                    PAGE.Run(PAGE::"Posted Service Invoice", ServInvHeader);
                                end;
                            "Document Type"::"Posted Credit Memo":
                                if ServCrMemoHeader.Get("Document No.") then begin
                                    isError := false;
                                    PAGE.Run(PAGE::"Posted Service Credit Memo", ServCrMemoHeader);
                                end;
                        end;
                    end;
                    if isError then
                        Error(Text001, "Document Type", "Document No.");
                end;
            }
        }
    }

    trigger OnInit()
    begin
        DocumentNoVisible := true;
        DocumentTypeVisible := true;
    end;

    var
        ServOrderHeaderRec: Record "Service Header";
        ServLogMgt: Codeunit ServLogManagement;
        Text001: Label 'Service %1 %2 does not exist.', Comment = 'Service Order 2001 does not exist.';
        [InDataSet]
        DocumentTypeVisible: Boolean;
        [InDataSet]
        DocumentNoVisible: Boolean;

    local procedure GetCaptionHeader(): Text[250]
    var
        ServHeader: Record "Service Header";
    begin
        if GetFilter("Document No.") <> '' then begin
            DocumentTypeVisible := false;
            DocumentNoVisible := false;
            if ServHeader.Get("Document Type", "Document No.") then
                exit(Format("Document Type") + ' ' + "Document No." + ' ' + ServHeader.Description);

            exit(Format("Document Type") + ' ' + "Document No.");
        end;

        DocumentTypeVisible := true;
        DocumentNoVisible := true;
        exit('');
    end;
}

