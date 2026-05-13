"""Statistical calculation utilities."""

def calculate_stats(numbers):
    """Calculate mean, median, mode, and standard deviation of a list of numbers.
    
    Returns a dict with keys: mean, median, mode, std_dev, min, max, count
    """
    if not numbers:
        return {"mean": 0, "median": 0, "mode": 0, "std_dev": 0, "min": 0, "max": 0, "count": 0}
    
    n = len(numbers)
    total = sum(numbers)
    mean = total / n
    
    # Mode
    from collections import Counter
    counter = Counter(numbers)
    mode = counter.most_common(1)[0][0]
    
    # Median
    sorted_nums = sorted(numbers)
    if n % 2 == 0:
        median = sorted_nums[n // 2]
    else:
        median = sorted_nums[(n - 1) // 2]
    
    # Standard deviation (population)
    variance = sum((x - mean) ** 2 for x in numbers) / n
    std_dev = variance ** 0.5
    
    return {
        "mean": round(mean, 2),
        "median": round(median, 2),
        "mode": mode,
        "std_dev": round(std_dev, 2),
        "min": min(numbers),
        "max": max(numbers),
        "count": n
    }


def normalize_scores(scores, target_mean=50, target_std=10):
    """Normalize a list of scores to have a target mean and standard deviation."""
    stats = calculate_stats(scores)
    if stats["std_dev"] == 0:
        return [target_mean] * len(scores)
    
    normalized = []
    for score in scores:
        z = (score - stats["mean"]) / stats["std_dev"]
        normalized.append(round(z * target_std + target_mean, 2))
    return normalized


def running_average(values):
    """Calculate the running/cumulative average of a list of values."""
    result = []
    total = 0
    for i, v in enumerate(values):
        total += v
        result.append(total / (i + 1))
    return result


def weighted_average(values, weights):
    """Calculate weighted average of values."""
    if len(values) != len(weights):
        raise ValueError("values and weights must have the same length")
    if sum(weights) == 0:
        return 0
    return sum(v * w for v, w in zip(values, weights)) / sum(weights)
