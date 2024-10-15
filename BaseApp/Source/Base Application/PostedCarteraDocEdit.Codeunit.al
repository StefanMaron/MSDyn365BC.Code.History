codeunit 7000009 "Posted Cartera Doc.- Edit"
{
    Permissions = TableData "Cartera Doc." = imd,
                  TableData "Posted Cartera Doc." = rm;
    TableNo = "Posted Cartera Doc.";

    trigger OnRun()
    begin
        PostedDoc := Rec;
        PostedDoc.LockTable();
        PostedDoc.Find;
        PostedDoc."Category Code" := "Category Code";
        PostedDoc."Due Date" := "Due Date";
        OnBeforeModifyPostedCarteraDoc(PostedDoc, Rec);
        PostedDoc.Modify();
        Rec := PostedDoc;
    end;

    var
        PostedDoc: Record "Posted Cartera Doc.";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPostedCarteraDoc(var PostedCarteraDoc: Record "Posted Cartera Doc."; CurrPostedCarteraDoc: Record "Posted Cartera Doc.")
    begin
    end;
}

