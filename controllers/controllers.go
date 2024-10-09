package controllers

type StopAndStartContainerRequest struct {
	ContainerID string `json:"container_id"`
}

type StatsContainer struct {
	StopAndStartContainerRequest
	CPUUsage     float64 `json:"cpu_usage"`
	RAMUsage     float64 `json:"ram_usage"`
	NetworkUsage float64 `json:"network_usage"`
}

type UpdateRequestConfigContainer struct {
	NanoCpus   int64 `json:"nano_cpus"`
	MemoryRam  int64 `json:"memory_ram"`
	MemorySwap int64 `json:"memory_swap"`
}
