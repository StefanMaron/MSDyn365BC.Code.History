permissionset 3922 "Intercompany - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Send/Receive Intercomp. Trans.';

    Permissions = tabledata "Handled IC Inbox Jnl. Line" = RIMD,
                  tabledata "Handled IC Inbox Purch. Header" = RIMD,
                  tabledata "Handled IC Inbox Purch. Line" = RIMD,
                  tabledata "Handled IC Inbox Sales Header" = RIMD,
                  tabledata "Handled IC Inbox Sales Line" = RIMD,
                  tabledata "Handled IC Inbox Trans." = RIMD,
                  tabledata "Handled IC Outbox Jnl. Line" = RIMD,
                  tabledata "Handled IC Outbox Purch. Hdr" = RIMD,
                  tabledata "Handled IC Outbox Purch. Line" = RIMD,
                  tabledata "Handled IC Outbox Sales Header" = RIMD,
                  tabledata "Handled IC Outbox Sales Line" = RIMD,
                  tabledata "Handled IC Outbox Trans." = RIMD,
                  tabledata "IC Comment Line" = RIMD,
                  tabledata "IC Document Dimension" = RIMD,
                  tabledata "IC Inbox Jnl. Line" = RIMD,
                  tabledata "IC Inbox Purchase Header" = RIMD,
                  tabledata "IC Inbox Purchase Line" = RIMD,
                  tabledata "IC Inbox Sales Header" = RIMD,
                  tabledata "IC Inbox Sales Line" = RIMD,
                  tabledata "IC Inbox Transaction" = RIMD,
                  tabledata "IC Inbox/Outbox Jnl. Line Dim." = RIMD,
                  tabledata "IC Outbox Jnl. Line" = RIMD,
                  tabledata "IC Outbox Purchase Header" = RIMD,
                  tabledata "IC Outbox Purchase Line" = RIMD,
                  tabledata "IC Outbox Sales Header" = RIMD,
                  tabledata "IC Outbox Sales Line" = RIMD,
                  tabledata "IC Outbox Transaction" = RIMD,
                  tabledata "IC Partner" = R;
}
