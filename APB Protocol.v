module APB_Memory (
    input              Pclk,
    input              Prst,
    input       [4:0]  Paddr,     // 32-depth memory → 5-bit address
    input              Pselx,
    input              Penable,
    input              Pwrite,
    input      [31:0]  Pwdata,
    output reg         Pready,
    output reg         Pslverr,
    output reg [31:0]  Prdata,
    output reg [31:0]  temp
);

    reg [31:0] mem [0:31];

    // FSM states
    parameter idle   = 2'b00;
    parameter setup  = 2'b01;
    parameter access = 2'b10;

    reg [1:0] present_state, next_state;

    // State register
    always @(posedge Pclk or negedge Prst) begin
        if (!Prst)
            present_state <= idle;
        else
            present_state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        next_state = present_state;
        case (present_state)
            idle: begin
                if (Pselx)
                    next_state = setup;
            end

            setup: begin
                if (Pselx && Penable)
                    next_state = access;
                else if (!Pselx)
                    next_state = idle;
            end

            access: begin
                if (!Pselx)
                    next_state = idle;
                else if (!Penable)
                    next_state = setup;
            end
        endcase
    end

    // Output logic
    always @(*) begin
        // Default values
        Pready  = 1'b0;
        Pslverr = 1'b0;
        Prdata  = 32'b0;
        temp    = 32'b0;

        if (present_state == access) begin
            Pready = 1'b1;

            if (Pwrite) begin
                // Write operation
                if (Paddr > 5'd31)
                    Pslverr = 1'b1;
                else begin
                    mem[Paddr] = Pwdata;
                    temp = mem[Paddr];
                end
            end
            else begin
                // Read operation
                if (Paddr > 5'd31)
                    Pslverr = 1'b1;
                else
                    Prdata = mem[Paddr];
            end
        end
    end

endmodule

     
    
