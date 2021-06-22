page 2115 "Report Viewer"
{
    Caption = 'Report Viewer';

    layout
    {
        area(content)
        {
            usercontrol(PdfViewer; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
            {
                ApplicationArea = Basic, Suite, Invoicing;

                trigger ControlAddInReady(callbackUrl: Text)
                begin
                    if DocumentContent = '' then
                        Error(NoDocErr);

                    CurrPage.PdfViewer.SetContent(DocumentContent);
                end;

                trigger DocumentReady()
                begin
                end;

                trigger Callback(data: Text)
                begin
                end;

                trigger Refresh(callbackUrl: Text)
                begin
                    if DocumentContent <> '' then
                        CurrPage.PdfViewer.SetContent(DocumentContent);
                end;
            }
        }
    }

    actions
    {
    }

    var
        DocumentContent: Text;
        NoDocErr: Label 'No document has been specified.';

    [Scope('OnPrem')]
    procedure SetDocument(RecordVariant: Variant; ReportType: Integer; CustNo: Code[20])
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.GetHtmlReport(DocumentContent, ReportType, RecordVariant, CustNo);
    end;
}

