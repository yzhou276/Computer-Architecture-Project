# Development Notes

Add `sqrt` and ``log2` instructions to the **RISCVpipelinedRV32IMFV1** core.

- modify `pl_id_cu` to decode new instructions and generate control signals

log2 rd, rs1, x0   -> rd = ceil(log2(rs1))
